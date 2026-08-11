#include "ApplicationRuntime.h"

#include <AEngine/Foundation/Error.h>

#include <utility>

namespace aengine::detail {

namespace {
constexpr const char* kOwner = "aengine_platform";
}

ApplicationRuntime::ApplicationRuntime(ApplicationPlatformServices&& services) noexcept
    : services_(std::move(services)) {
    trace_.Record(ApplicationTraceEvent::Initialized, frameIndex_);
}

int ApplicationRuntime::Run() {
    if (runActive_) {
        return 2;
    }

    if (lifecycle_.State() == ApplicationState::Stopped) {
        return 0;
    }

    runActive_ = true;
    for (;;) {
        auto frame = PumpOwnedFrame();
        if (!frame) {
            runActive_ = false;
            return 1;
        }
        if (!frame.Value()) {
            runActive_ = false;
            return 0;
        }
    }
}

Result<bool> ApplicationRuntime::PumpFrame() {
    if (runActive_) {
        return Result<bool>::Failure(MakeError(
            ErrorCode::Busy,
            "PumpFrame cannot run while App::Run owns the application loop",
            kOwner));
    }

    return PumpOwnedFrame();
}

void ApplicationRuntime::RequestQuit() noexcept {
    if (lifecycle_.RequestQuit()) {
        trace_.Record(ApplicationTraceEvent::QuitRequested, frameIndex_);
    }
}

void ApplicationRuntime::Shutdown() noexcept {
    if (lifecycle_.Stop()) {
        trace_.Record(ApplicationTraceEvent::Stopped, frameIndex_);
    }
}

ApplicationState ApplicationRuntime::State() const noexcept {
    return lifecycle_.State();
}

ApplicationTraceView ApplicationRuntime::Trace() const noexcept {
    return trace_.View();
}

FrameTimeSample ApplicationRuntime::CurrentFrameTime() const noexcept {
    return frameTime_;
}

Result<bool> ApplicationRuntime::PumpOwnedFrame() {
    switch (lifecycle_.ReachFrameBoundary()) {
    case FrameBoundaryDecision::PumpFrame:
        frameTime_ = services_.Time().AdvanceFrame();
        ++frameIndex_;
        trace_.Record(ApplicationTraceEvent::FramePumped, frameIndex_);
        return Result<bool>::Success(true);

    case FrameBoundaryDecision::Stop:
        trace_.Record(ApplicationTraceEvent::Stopped, frameIndex_);
        return Result<bool>::Success(false);

    case FrameBoundaryDecision::Invalid:
        return Result<bool>::Failure(MakeError(
            ErrorCode::InvalidState,
            "application is already stopped",
            kOwner));
    }

    return Result<bool>::Failure(MakeError(
        ErrorCode::InternalFailure,
        "unknown application frame-boundary decision",
        kOwner));
}

}
