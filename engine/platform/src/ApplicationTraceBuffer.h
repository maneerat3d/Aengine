#pragma once

#include <AEngine/Application/ApplicationTrace.h>

#include <array>
#include <cstddef>
#include <cstdint>

namespace aengine::detail {

class ApplicationTraceBuffer {
public:
    void Record(ApplicationTraceEvent event, std::uint64_t frameIndex) noexcept;
    [[nodiscard]] ApplicationTraceView View() const noexcept;

private:
    static constexpr std::size_t kCapacity = 128;

    std::array<ApplicationTraceEntry, kCapacity> entries_{};
    std::size_t size_ = 0;
    std::uint64_t nextSequence_ = 1;
    bool truncated_ = false;
};

}
