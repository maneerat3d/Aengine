#pragma once

#include "TimePort.h"

#include <memory>
#include <utility>

namespace aengine::detail {

class ApplicationPlatformServices {
public:
    explicit ApplicationPlatformServices(std::unique_ptr<TimePort> timePort) noexcept
        : timePort_(std::move(timePort)) {}

    ApplicationPlatformServices(ApplicationPlatformServices&&) noexcept = default;
    ApplicationPlatformServices& operator=(ApplicationPlatformServices&&) noexcept = default;

    ApplicationPlatformServices(const ApplicationPlatformServices&) = delete;
    ApplicationPlatformServices& operator=(const ApplicationPlatformServices&) = delete;

    [[nodiscard]] bool IsValid() const noexcept { return timePort_ != nullptr; }
    [[nodiscard]] TimePort& Time() noexcept { return *timePort_; }
    [[nodiscard]] const TimePort& Time() const noexcept { return *timePort_; }

private:
    std::unique_ptr<TimePort> timePort_;
};

}
