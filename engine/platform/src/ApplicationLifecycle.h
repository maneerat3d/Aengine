#pragma once

#include <AEngine/Application/ApplicationState.h>

namespace aengine::detail {

enum class FrameBoundaryDecision {
    PumpFrame,
    Stop,
    Invalid,
};

class ApplicationLifecycle {
public:
    [[nodiscard]] ApplicationState State() const noexcept { return state_; }
    [[nodiscard]] bool RequestQuit() noexcept;
    [[nodiscard]] FrameBoundaryDecision ReachFrameBoundary() noexcept;
    [[nodiscard]] bool Stop() noexcept;

private:
    ApplicationState state_ = ApplicationState::Running;
};

}
