#include "ApplicationPlatformServices.h"
#include "ApplicationRuntime.h"
#include "FixedStepTimePort.h"

#include <cstdlib>
#include <iostream>
#include <memory>
#include <utility>

namespace {

void Require(bool condition, const char* message) {
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
        std::exit(1);
    }
}

struct ProbeState {
    std::uint64_t calls = 0;
    std::uint64_t elapsedNanoseconds = 0;
};

class ProbeTimePort final : public aengine::detail::TimePort {
public:
    explicit ProbeTimePort(ProbeState& state) noexcept
        : state_(state) {}

    [[nodiscard]] aengine::detail::FrameTimeSample AdvanceFrame() noexcept override {
        ++state_.calls;
        state_.elapsedNanoseconds += 7;
        return aengine::detail::FrameTimeSample{
            .elapsedNanoseconds = state_.elapsedNanoseconds,
            .deltaNanoseconds = 7,
        };
    }

private:
    ProbeState& state_;
};

void TestFixedStepTimePort() {
    aengine::detail::FixedStepTimePort time{10};

    const auto first = time.AdvanceFrame();
    Require(first.elapsedNanoseconds == 10, "first fixed-step sample must advance once");
    Require(first.deltaNanoseconds == 10, "fixed-step delta must equal configured step");

    const auto second = time.AdvanceFrame();
    Require(second.elapsedNanoseconds == 20, "fixed-step elapsed time must be deterministic");
    Require(second.deltaNanoseconds == 10, "fixed-step delta must remain stable");
}

void TestRuntimeUsesInjectedTimePortAtFrameBoundary() {
    ProbeState probe{};
    std::unique_ptr<aengine::detail::TimePort> timePort{
        new ProbeTimePort{probe}};
    aengine::detail::ApplicationPlatformServices services{std::move(timePort)};
    Require(services.IsValid(), "platform service bundle must own the injected time port");

    aengine::detail::ApplicationRuntime runtime{std::move(services)};
    Require(probe.calls == 0, "runtime construction must not advance frame time");

    auto first = runtime.PumpFrame();
    Require(first && first.Value(), "first runtime frame must pump");
    Require(probe.calls == 1, "one pumped frame must advance time exactly once");
    Require(runtime.CurrentFrameTime().elapsedNanoseconds == 7,
            "runtime must retain the injected first frame sample");

    auto second = runtime.PumpFrame();
    Require(second && second.Value(), "second runtime frame must pump");
    Require(probe.calls == 2, "two pumped frames must advance time exactly twice");
    Require(runtime.CurrentFrameTime().elapsedNanoseconds == 14,
            "runtime must retain the injected second frame sample");

    runtime.RequestQuit();
    auto stopped = runtime.PumpFrame();
    Require(stopped && !stopped.Value(), "quit boundary must stop without pumping a frame");
    Require(probe.calls == 2, "quit-only safe boundary must not advance time");
    Require(runtime.CurrentFrameTime().elapsedNanoseconds == 14,
            "quit-only safe boundary must preserve the last frame sample");
}

}

int main() {
    TestFixedStepTimePort();
    TestRuntimeUsesInjectedTimePortAtFrameBoundary();
    return 0;
}
