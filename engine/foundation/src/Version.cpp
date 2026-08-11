#include <AEngine/Foundation/Version.h>

#include <string_view>

namespace aengine {
namespace {

constexpr std::string_view BuildConfiguration() {
#if defined(AENGINE_BUILD_CONFIGURATION)
    return AENGINE_BUILD_CONFIGURATION;
#else
    return "unknown";
#endif
}

constexpr std::string_view CompilerName() {
#if defined(_MSC_VER)
    return "MSVC";
#elif defined(__clang__)
    return "Clang";
#elif defined(__GNUC__)
    return "GCC";
#else
    return "unknown";
#endif
}

}

ApiVersion GetApiVersion() noexcept {
    return ApiVersion{0, 1, 0};
}

CapabilitySet GetCapabilities() noexcept {
    return CapabilitySet{Capability::Foundation | Capability::Headless};
}

BuildIdentity GetBuildIdentity() noexcept {
    return BuildIdentity{
        .apiVersion = GetApiVersion(),
        .configuration = BuildConfiguration(),
        .compiler = CompilerName(),
    };
}

}
