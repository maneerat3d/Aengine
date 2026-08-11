#include <AEngine/Application.h>
#include <AEngine/Platform/Time.h>

#include <cstdlib>
#include <iostream>
#include <utility>

namespace {

void Require(bool condition, const char* message) {
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
        std::exit(1);
    }
}

aengine::AppConfig ValidConfig() {
    static constexpr char kName[] = "application-contract-test";
    return aengine::AppConfig{
        .name = aengine::Utf8View{kName, sizeof(kName) - 1},
    };
}

class FixedTimeSource final : public aengine::ITimeSource {
public:
    explicit FixedTimeSource(std::int64_t nanoseconds) noexcept
        : nanoseconds_(nanoseconds) {}

    [[nodiscard]] aengine::MonotonicTimePoint Now() const noexcept override {
        return aengine::MonotonicTimePoint{nanoseconds_};
    }

private:
    std::int64_t nanoseconds_ = 0;
};

void TestTimePortContract() {
    FixedTimeSource fixed{42};
    const aengine::ITimeSource& port = fixed;
    Require(port.Now().nanoseconds == 42,
            "time port must be substitutable through the public interface");

    auto created = aengine::CreateMonotonicTimeSource();
    Require(static_cast<bool>(created),
            "production monotonic time source creation must succeed");

    const auto first = created.Value()->Now();
    const auto second = created.Value()->Now();
    Require(second.nanoseconds >= first.nanoseconds,
            "production monotonic time source must not move backwards");
}

void TestStartupValidation() {
    const auto failed = aengine::App::Init({});
    Require(!failed, "empty AppConfig must fail startup");
    Require(failed.Error().code == aengine::ErrorCode::InvalidArgument,
            "invalid startup must report InvalidArgument");
    Require(failed.Error().owner == "aengine_platform",
            "startup error must identify platform owner");
    Require(failed.Error().operationId.IsValid(),
            "startup error must carry an operation ID");
}

void TestManualLifecycleAndTrace() {
    auto initialized = aengine::App::Init(ValidConfig());
    Require(static_cast<bool>(initialized), "valid app initialization must succeed");
    auto app = std::move(initialized).Value();

    Require(app.State() == aengine::ApplicationState::Running,
            "initialized app must be running");
    auto trace = app.Trace();
    Require(trace.size == 1, "initialization must create one trace entry");
    Require(trace.data[0].sequence == 1, "trace sequence must start at one");
    Require(trace.data[0].event == aengine::ApplicationTraceEvent::Initialized,
            "first trace entry must be Initialized");

    for (std::uint64_t expectedFrame = 1; expectedFrame <= 2; ++expectedFrame) {
        auto frame = app.PumpFrame();
        Require(static_cast<bool>(frame), "manual frame pump must succeed");
        Require(frame.Value(), "running frame pump must request another frame");
        trace = app.Trace();
        const auto& entry = trace.data[trace.size - 1];
        Require(entry.event == aengine::ApplicationTraceEvent::FramePumped,
                "frame pump must append FramePumped trace event");
        Require(entry.frameIndex == expectedFrame,
                "frame trace index must be deterministic");
    }

    app.Quit();
    Require(app.State() == aengine::ApplicationState::QuitRequested,
            "Quit must request shutdown without stopping immediately");
    const auto quitTraceSize = app.Trace().size;
    app.Quit();
    Require(app.Trace().size == quitTraceSize,
            "repeated Quit must not duplicate the quit transition");

    auto stop = app.PumpFrame();
    Require(static_cast<bool>(stop), "quit boundary pump must succeed");
    Require(!stop.Value(), "quit boundary pump must stop the application");
    Require(app.State() == aengine::ApplicationState::Stopped,
            "quit must become Stopped at the next safe frame boundary");

    trace = app.Trace();
    Require(trace.data[trace.size - 2].event == aengine::ApplicationTraceEvent::QuitRequested,
            "trace must record QuitRequested before Stopped");
    Require(trace.data[trace.size - 1].event == aengine::ApplicationTraceEvent::Stopped,
            "trace must record Stopped at the safe frame boundary");
    Require(!trace.truncated, "short lifecycle trace must not truncate");

    const auto afterStop = app.PumpFrame();
    Require(!afterStop, "pumping a stopped app must fail");
    Require(afterStop.Error().code == aengine::ErrorCode::InvalidState,
            "stopped app pump must report InvalidState");
}

void TestOwnedRunConsumesPendingQuit() {
    auto initialized = aengine::App::Init(ValidConfig());
    Require(static_cast<bool>(initialized), "run test initialization must succeed");
    auto app = std::move(initialized).Value();

    app.Quit();
    Require(app.Run() == 0, "Run must consume a pending quit at its first safe boundary");
    Require(app.State() == aengine::ApplicationState::Stopped,
            "Run must finish in Stopped state after pending quit");
}

}

int main() {
    TestTimePortContract();
    TestStartupValidation();
    TestManualLifecycleAndTrace();
    TestOwnedRunConsumesPendingQuit();
    return 0;
}
