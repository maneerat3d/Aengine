#pragma once

#include <AEngine/Application/AppConfig.h>
#include <AEngine/Application/ApplicationState.h>
#include <AEngine/Application/ApplicationTrace.h>
#include <AEngine/Foundation/Result.h>

namespace aengine {

class App {
public:
    ~App();

    App(App&& other) noexcept;
    App& operator=(App&& other) noexcept;

    App(const App&) = delete;
    App& operator=(const App&) = delete;

    [[nodiscard]] static Result<App> Init(const AppConfig& config);

    [[nodiscard]] int Run();
    [[nodiscard]] Result<bool> PumpFrame();
    void Quit() noexcept;

    [[nodiscard]] ApplicationState State() const noexcept;
    [[nodiscard]] ApplicationTraceView Trace() const noexcept;

private:
    struct Impl;

    explicit App(Impl* impl) noexcept;
    void Reset() noexcept;

    Impl* impl_ = nullptr;
};

}
