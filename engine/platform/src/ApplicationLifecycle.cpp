#include "ApplicationLifecycle.h"

namespace aengine::detail {

bool ApplicationLifecycle::RequestQuit() noexcept {
    if (state_ != ApplicationState::Running) {
        return false;
    }

    state_ = ApplicationState::QuitRequested;
    return true;
}

FrameBoundaryDecision ApplicationLifecycle::ReachFrameBoundary() noexcept {
    if (state_ == ApplicationState::Running) {
        return FrameBoundaryDecision::PumpFrame;
    }

    if (state_ == ApplicationState::QuitRequested) {
        state_ = ApplicationState::Stopped;
        return FrameBoundaryDecision::Stop;
    }

    return FrameBoundaryDecision::Invalid;
}

bool ApplicationLifecycle::Stop() noexcept {
    if (state_ == ApplicationState::Stopped) {
        return false;
    }

    state_ = ApplicationState::Stopped;
    return true;
}

}
