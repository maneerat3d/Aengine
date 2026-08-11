#include <AEngine/Application.h>
#include <AEngine/Platform/Time.h>

#include <cstddef>
#include <iostream>
#include <utility>

namespace {

const char* StateName(aengine::ApplicationState state) noexcept {
    switch (state) {
    case aengine::ApplicationState::Running:
        return "running";
    case aengine::ApplicationState::QuitRequested:
        return "quit-requested";
    case aengine::ApplicationState::Stopped:
        return "stopped";
    }
    return "unknown";
}

}

int main() {
    auto timeResult = aengine::CreateMonotonicTimeSource();
    if (!timeResult) {
        std::cerr << "time_error=" << static_cast<unsigned>(timeResult.Error().code) << '\n';
        return 1;
    }
    auto timeSource = std::move(timeResult).Value();
    const auto startTime = timeSource->Now();

    constexpr char kName[] = "aengine_headless";
    const aengine::AppConfig config{
        .name = aengine::Utf8View{kName, sizeof(kName) - 1},
    };

    auto appResult = aengine::App::Init(config);
    if (!appResult) {
        std::cerr << "init_error=" << static_cast<unsigned>(appResult.Error().code) << '\n';
        return 2;
    }

    auto app = std::move(appResult).Value();
    constexpr std::size_t kFramesToPump = 3;
    for (std::size_t frameIndex = 0; frameIndex < kFramesToPump; ++frameIndex) {
        auto frame = app.PumpFrame();
        if (!frame || !frame.Value()) {
            return 3;
        }
    }

    app.Quit();
    auto stop = app.PumpFrame();
    if (!stop || stop.Value()) {
        return 4;
    }

    const auto endTime = timeSource->Now();
    if (endTime.nanoseconds < startTime.nanoseconds) {
        return 5;
    }

    const auto trace = app.Trace();
    std::cout << "frames=" << kFramesToPump
              << " state=" << StateName(app.State())
              << " trace=" << trace.size
              << " truncated=" << (trace.truncated ? 1 : 0)
              << " time_ns=" << endTime.nanoseconds
              << '\n';
    return 0;
}
