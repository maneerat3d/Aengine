#pragma once

#include <cstdint>
#include <limits>

namespace aengine {

template <class Tag>
struct Handle {
    std::uint32_t slot = std::numeric_limits<std::uint32_t>::max();
    std::uint32_t generation = 0;

    [[nodiscard]] constexpr bool IsValid() const noexcept {
        return slot != std::numeric_limits<std::uint32_t>::max() && generation != 0;
    }

    friend constexpr bool operator==(Handle, Handle) = default;
};

}
