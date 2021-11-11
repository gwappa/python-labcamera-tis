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
#ifndef LISTENERS_HPP_
#include <tisudshl.h>

typedef void (*FrameCallback)(size_t size, void *data, void *user_data);

class DefaultFrameNotificationSinkListener: public DShowLib::FrameNotificationSinkListener
{
private:
    const FrameCallback callback;
          void         *user_data;
public:
    DefaultFrameNotificationSinkListener(FrameCallback callback, void *user_data);
    void sinkConnected(const DShowLib::FrameTypeInfo& info) override { };
    void sinkDisconnected() override { };
    void frameReceived(DShowLib::IFrame& frame) override;
};

class DefaultFrameQueueSinkListener: public DShowLib::FrameQueueSinkListener
{
private:
    const FrameCallback callback;
          void         *user_data;

public:
    DefaultFrameQueueSinkListener(FrameCallback callback, void *user_data);

    void framesQueued(const DShowLib::FrameQueueSink& sink); // override;
    void sinkConnected(DShowLib::FrameQueueSink& sink, const DShowLib::FrameTypeInfo& info) override;
    void sinkDisconnected(DShowLib::FrameQueueSink& sink) override;
};

#define LISTENERS_HPP_
#endif
