#pragma once

#include <AEngine/Foundation/Error.h>
#include <AEngine/Foundation/Handle.h>

#include <cstdint>

namespace aengine {

struct JobTag;
using JobHandle = Handle<JobTag>;

enum class JobState : std::uint8_t {
    Queued,
    Running,
    Succeeded,
    Failed,
    Cancelled,
};

struct JobStatus {
    JobState state = JobState::Queued;
    float progress = 0.0F;
    OperationId operationId{};
    Error error{};
};

}
