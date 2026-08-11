#pragma once

#include "ApplicationLifecycle.h"
#include "ApplicationTraceBuffer.h"

#include <AEngine/Foundation/Result.h>

#include <cstdint>

namespace aengine::detail {

class ApplicationRuntime {
public:
    ApplicationRuntime() noexcept;

    [[nodiscard]] int Run();
    [[nodiscard]] Result<bool> PumpFrame();
    void RequestQuit() noexcept;
    void Shutdown() noexcept;

    [[nodiscard]] ApplicationState State() const noexcept;
    [[nodiscard]] ApplicationTraceView Trace() const noexcept;

private:
    [[nodiscard]] Result<bool> PumpOwnedFrame();

    ApplicationLifecycle lifecycle_{};
    ApplicationTraceBuffer trace_{};
    std::uint64_t frameIndex_ = 0;
    bool runActive_ = false;
};

}
