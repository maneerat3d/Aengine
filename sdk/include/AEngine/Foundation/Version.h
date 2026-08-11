#pragma once

#include <cstdint>
#include <string_view>

namespace aengine {

struct ApiVersion {
    std::uint32_t major = 0;
    std::uint32_t minor = 0;
    std::uint32_t patch = 0;
};

enum class Capability : std::uint64_t {
    Foundation = 1ULL << 0U,
    Headless = 1ULL << 1U,
};

class CapabilitySet {
public:
    constexpr CapabilitySet() = default;
    constexpr CapabilitySet(Capability capability)
        : bits_(static_cast<std::uint64_t>(capability)) {}
    constexpr CapabilitySet(Capability left, Capability right)
        : bits_(static_cast<std::uint64_t>(left) | static_cast<std::uint64_t>(right)) {}

    [[nodiscard]] constexpr bool Supports(Capability capability) const noexcept {
        return (bits_ & static_cast<std::uint64_t>(capability)) != 0;
    }
    [[nodiscard]] constexpr std::uint64_t Bits() const noexcept { return bits_; }

private:
    std::uint64_t bits_ = 0;
};

[[nodiscard]] constexpr CapabilitySet operator|(Capability left, Capability right) noexcept {
    return CapabilitySet(left, right);
}

struct BuildIdentity {
    ApiVersion apiVersion{};
    std::string_view configuration;
    std::string_view compiler;
};

[[nodiscard]] ApiVersion GetApiVersion() noexcept;
[[nodiscard]] CapabilitySet GetCapabilities() noexcept;
[[nodiscard]] BuildIdentity GetBuildIdentity() noexcept;

}
