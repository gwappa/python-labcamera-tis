/*
 *  MIT License
 *
 *  Copyright (c) 2021 Keisuke Sehara
 *
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *
 *  The above copyright notice and this permission notice shall be included in all
 *  copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 *  SOFTWARE.
*/
#include "sink_utils.hpp"
#include <iostream>

DefaultFrameNotificationSinkListener::DefaultFrameNotificationSinkListener(FrameCallback callback, void *user_data):
    callback_(callback), user_data_(user_data), count_(0) { }

void DefaultFrameNotificationSinkListener::setCallback(FrameCallback callback)
{
    callback_ = callback;
}

void DefaultFrameNotificationSinkListener::frameReceived(DShowLib::IFrame &frame)
{
    count_++;
    if (callback_ != nullptr) {
        callback_(frame.getActualDataSize(),
                 frame.getPtr(),
                 user_data_);
    }
}

void DefaultFrameNotificationSinkListener::sinkConnected(const DShowLib::FrameTypeInfo& info)
{
    count_ = 0;
}

void DefaultFrameNotificationSinkListener::sinkDisconnected()
{
    if (callback_ != nullptr) {
        // mark end-of-acquisition
        callback_(0, nullptr, user_data_);
    }

    std::cerr << "received " << count_ << " frames in total" << std::endl;
}

void dequeue_context(DefaultFrameQueueSinkListener *listener) {
    listener->run();
}

DefaultFrameQueueSinkListener::DefaultFrameQueueSinkListener(FrameCallback callback, void *user_data):
    callback_(callback),
    user_data_(user_data),
    size_(0),
    buffer_count_(0),
    quit_(false) { }

void DefaultFrameQueueSinkListener::sinkConnected(DShowLib::FrameQueueSink& sink, const DShowLib::FrameTypeInfo& info)
{
    sink_   = &sink;
    size_   = info.buffersize;
    quit_   = false; // just in case it is reused
    thread_ = std::thread(dequeue_context, this);

    if (buffer_count_ > 0) {
        DShowLib::Error ret = sink.allocAndQueueBuffers(buffer_count_);
        if (ret.isError()) {
            std::cerr << "***failed to allocate frames: "
                      << ret.toString() << std::endl;
        }
    }
}

void DefaultFrameQueueSinkListener::framesQueued(DShowLib::FrameQueueSink& sink)
{
    std::unique_lock<std::mutex> lock(io_);
    quit_ = sink_->isCancelRequested();
    reception_.notify_one(); // supposed to be the dequeue thread
}

void DefaultFrameQueueSinkListener::sinkDisconnected(DShowLib::FrameQueueSink& sink)
{
    mark_quit_();
    thread_.join();

    while(sink_->getOutputQueueSize() > 0) {
        process_single_();
    }

    // mark end-of-acquisition
    callback_(0, nullptr, user_data_);
    sink_ = nullptr;

    auto info = sink.getFrameCountInfo();
    std::cerr << ">>> buffer stats: copied " << info.framesCopied
              << " frames, dropped " << info.framesDropped << " frames" << std::endl;
}

void DefaultFrameQueueSinkListener::run()
{
    while(true)
    {
        if (!wait_next_()) {
            break;
        }
        process_single_();
    }
}

bool DefaultFrameQueueSinkListener::wait_next_()
{
    while (sink_->getOutputQueueSize() == 0) {
        std::unique_lock<std::mutex> lock(io_);
        reception_.wait(lock);
        if (quit_) {
            return false;
        }
    }
    return true;
}

void DefaultFrameQueueSinkListener::process_single_()
{
    DShowLib::tFrameQueueBufferPtr frame = sink_->popOutputQueueBuffer();
    callback_(size_, frame->getPtr(), user_data_);
    sink_->queueBuffer(frame);
}

void DefaultFrameQueueSinkListener::mark_quit_()
{
    std::unique_lock<std::mutex> lock(io_);
    quit_ = true;
    reception_.notify_all();
}
