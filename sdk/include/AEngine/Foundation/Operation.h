#pragma once

#include <cstdint>

namespace aengine {

struct OperationId {
    std::uint64_t value = 0;

    [[nodiscard]] constexpr bool IsValid() const noexcept { return value != 0; }
    [[nodiscard]] static OperationId New() noexcept;
    friend constexpr bool operator==(OperationId, OperationId) = default;
};

}
