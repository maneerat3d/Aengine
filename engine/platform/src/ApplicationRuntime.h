#pragma once

#include "ApplicationLifecycle.h"
#include "ApplicationPlatformServices.h"
#include "ApplicationTraceBuffer.h"

#include <AEngine/Foundation/Result.h>

#include <cstdint>

namespace aengine::detail {

class ApplicationRuntime {
public:
    explicit ApplicationRuntime(ApplicationPlatformServices&& services) noexcept;

    [[nodiscard]] int Run();
    [[nodiscard]] Result<bool> PumpFrame();
    void RequestQuit() noexcept;
    void Shutdown() noexcept;

    [[nodiscard]] ApplicationState State() const noexcept;
    [[nodiscard]] ApplicationTraceView Trace() const noexcept;
    [[nodiscard]] FrameTimeSample CurrentFrameTime() const noexcept;

private:
    [[nodiscard]] Result<bool> PumpOwnedFrame();

    ApplicationPlatformServices services_;
    ApplicationLifecycle lifecycle_{};
    ApplicationTraceBuffer trace_{};
    std::uint64_t frameIndex_ = 0;
    FrameTimeSample frameTime_{};
    bool runActive_ = false;
};

}
