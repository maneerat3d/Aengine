#include <AEngine/Application/App.h>

#include "ApplicationCompositionRoot.h"

#include <AEngine/Foundation/Error.h>

#include <new>
#include <utility>

namespace aengine {

struct App::Impl {
    explicit Impl(detail::ApplicationRuntime&& runtimeValue) noexcept
        : runtime(std::move(runtimeValue)) {}

    detail::ApplicationRuntime runtime;
};

App::App(Impl* impl) noexcept
    : impl_(impl) {}

App::~App() {
    Reset();
}

App::App(App&& other) noexcept
    : impl_(std::exchange(other.impl_, nullptr)) {}

App& App::operator=(App&& other) noexcept {
    if (this == &other) {
        return *this;
    }

    Reset();
    impl_ = std::exchange(other.impl_, nullptr);
    return *this;
}

Result<App> App::Init(const AppConfig& config) {
    auto runtime = detail::ComposeApplication(config);
    if (!runtime) {
        return Result<App>::Failure(runtime.Error());
    }

    auto* impl = new (std::nothrow) Impl(std::move(runtime).Value());
    if (impl == nullptr) {
        return Result<App>::Failure(MakeError(
            ErrorCode::ResourceExhausted,
            "failed to allocate application runtime",
            "aengine_platform"));
    }

    return Result<App>::Success(App{impl});
}

int App::Run() {
    return impl_ != nullptr ? impl_->runtime.Run() : 1;
}

Result<bool> App::PumpFrame() {
    if (impl_ == nullptr) {
        return Result<bool>::Failure(MakeError(
            ErrorCode::InvalidState,
            "application has no runtime",
            "aengine_platform"));
    }

    return impl_->runtime.PumpFrame();
}

void App::Quit() noexcept {
    if (impl_ != nullptr) {
        impl_->runtime.RequestQuit();
    }
}

ApplicationState App::State() const noexcept {
    return impl_ != nullptr ? impl_->runtime.State() : ApplicationState::Stopped;
}

ApplicationTraceView App::Trace() const noexcept {
    return impl_ != nullptr ? impl_->runtime.Trace() : ApplicationTraceView{};
}

void App::Reset() noexcept {
    if (impl_ == nullptr) {
        return;
    }

    impl_->runtime.Shutdown();
    delete impl_;
    impl_ = nullptr;
}

}
