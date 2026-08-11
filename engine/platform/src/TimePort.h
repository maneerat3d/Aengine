#pragma once

#include <cstdint>

namespace aengine::detail {

struct FrameTimeSample {
    std::uint64_t elapsedNanoseconds = 0;
    std::uint64_t deltaNanoseconds = 0;
};

class TimePort {
public:
    virtual ~TimePort() = default;

    TimePort(const TimePort&) = delete;
    TimePort& operator=(const TimePort&) = delete;

    [[nodiscard]] virtual FrameTimeSample AdvanceFrame() noexcept = 0;

protected:
    TimePort() = default;
};

}
