#pragma once

#include <cstddef>
#include <span>
#include <string_view>

namespace aengine {

struct Utf8View {
    const char* data = nullptr;
    std::size_t size = 0;

    [[nodiscard]] constexpr bool Empty() const noexcept { return size == 0; }
    [[nodiscard]] constexpr std::string_view AsStringView() const noexcept {
        return std::string_view{data, size};
    }
};

struct ByteView {
    const std::byte* data = nullptr;
    std::size_t size = 0;

    [[nodiscard]] constexpr bool Empty() const noexcept { return size == 0; }
    [[nodiscard]] constexpr std::span<const std::byte> AsSpan() const noexcept {
        return std::span<const std::byte>{data, size};
    }
};

}
