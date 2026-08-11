#pragma once

#include <cstddef>
#include <cstdint>
#include <span>

namespace aengine {

enum class ApplicationTraceEvent : std::uint8_t {
    Initialized = 0,
    FramePumped,
    QuitRequested,
    Stopped,
};

struct ApplicationTraceEntry {
    std::uint64_t sequence = 0;
    std::uint64_t frameIndex = 0;
    ApplicationTraceEvent event = ApplicationTraceEvent::Initialized;
};

struct ApplicationTraceView {
    const ApplicationTraceEntry* data = nullptr;
    std::size_t size = 0;
    bool truncated = false;

    [[nodiscard]] constexpr std::span<const ApplicationTraceEntry> AsSpan() const noexcept {
        return std::span<const ApplicationTraceEntry>{data, size};
    }
};

}
