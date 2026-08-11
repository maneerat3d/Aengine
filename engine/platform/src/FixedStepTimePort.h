#pragma once

#include "TimePort.h"

#include <cstdint>

namespace aengine::detail {

class FixedStepTimePort final : public TimePort {
public:
    explicit FixedStepTimePort(std::uint64_t frameStepNanoseconds) noexcept
        : frameStepNanoseconds_(frameStepNanoseconds) {}

    [[nodiscard]] FrameTimeSample AdvanceFrame() noexcept override {
        elapsedNanoseconds_ += frameStepNanoseconds_;
        return FrameTimeSample{
            .elapsedNanoseconds = elapsedNanoseconds_,
            .deltaNanoseconds = frameStepNanoseconds_,
        };
    }

private:
    std::uint64_t frameStepNanoseconds_ = 0;
    std::uint64_t elapsedNanoseconds_ = 0;
};

}
