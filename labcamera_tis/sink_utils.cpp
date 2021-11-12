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
    callback(callback), user_data(user_data) { }

void DefaultFrameNotificationSinkListener::frameReceived(DShowLib::IFrame &frame)
{
    callback(frame.getActualDataSize(),
             frame.getPtr(),
             user_data);
}

void DefaultFrameNotificationSinkListener::sinkDisconnected()
{
    // mark end-of-acquisition
    callback(0, nullptr, user_data);
}

void dequeue_context(DefaultFrameQueueSinkListener *listener) {
    listener->run();
}

DefaultFrameQueueSinkListener::DefaultFrameQueueSinkListener(FrameCallback callback, void *user_data):
    callback_(callback), user_data_(user_data), size_(0), quit_(false) { }

void DefaultFrameQueueSinkListener::sinkConnected(DShowLib::FrameQueueSink& sink, const DShowLib::FrameTypeInfo& info)
{
    sink_   = &sink;
    size_   = info.buffersize;
    quit_   = false; // just in case it is reused
    thread_ = std::thread(dequeue_context, this);
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
    if (sink_->getOutputQueueSize() == 0) {
        std::unique_lock<std::mutex> lock(io_);
        reception_.wait(lock);
    }
    return !quit_;
}

void DefaultFrameQueueSinkListener::process_single_()
{
    DShowLib::tFrameQueueBufferPtr frame = sink_->popOutputQueueBuffer();
    callback_(size_, frame->getUserPointer(), user_data_);
}

void DefaultFrameQueueSinkListener::mark_quit_()
{
    std::unique_lock<std::mutex> lock(io_);
    quit_ = true;
    reception_.notify_all();
}
smart_ptr<DShowLib::GrabberSinkType> setup_sink(
    smart_ptr<DShowLib::FrameNotificationSink> src,
    size_t n_buffers
) {
    (void *)n_buffers; // NOT USED
    return src;
}

smart_ptr<DShowLib::GrabberSinkType> setup_sink(
    smart_ptr<DShowLib::FrameQueueSink> src,
    size_t n_buffers
) {
    if (n_buffers > 0) {
        DShowLib::Error ret = src->allocAndQueueBuffers(n_buffers);
        if (ret.isError()) {
            std::cerr << "failed to allocate input frame buffers: "
                     << ret.toString() << std::endl;
        }
    }
    return src;
}
