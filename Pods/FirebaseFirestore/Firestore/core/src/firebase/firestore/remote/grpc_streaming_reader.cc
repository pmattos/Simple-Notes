/*
 * Copyright 2018 Google
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "Firestore/core/src/firebase/firestore/remote/grpc_streaming_reader.h"

#include <utility>

#include "Firestore/core/src/firebase/firestore/util/hard_assert.h"

namespace firebase {
namespace firestore {
namespace remote {

using util::AsyncQueue;
using util::Status;
using util::StatusOr;

GrpcStreamingReader::GrpcStreamingReader(
    std::unique_ptr<grpc::ClientContext> context,
    std::unique_ptr<grpc::GenericClientAsyncReaderWriter> call,
    util::AsyncQueue* worker_queue,
    const grpc::ByteBuffer& request)
    : stream_{absl::make_unique<GrpcStream>(
          std::move(context), std::move(call), this, worker_queue)},
      request_{request} {
}

void GrpcStreamingReader::Start(CallbackT&& callback) {
  callback_ = std::move(callback);
  stream_->Start();
}

void GrpcStreamingReader::Cancel() {
  stream_->Finish();
}

void GrpcStreamingReader::OnStreamStart() {
  // It is important to indicate to the server that there will be no follow-up
  // writes; otherwise, the call will never finish.
  stream_->WriteLast(std::move(request_));
}

void GrpcStreamingReader::OnStreamRead(const grpc::ByteBuffer& message) {
  // Accumulate responses
  responses_.push_back(message);
}

void GrpcStreamingReader::OnStreamFinish(const util::Status& status) {
  HARD_ASSERT(callback_,
              "Received an event from stream after callback was unset");
  if (status.ok()) {
    callback_(responses_);
  } else {
    callback_(status);
  }
  callback_ = {};
}

}  // namespace remote
}  // namespace firestore
}  // namespace firebase
