#include <AEngine/Foundation/Diagnostics.h>
#include <AEngine/Foundation/Version.h>

#include <atomic>
#include <utility>

namespace aengine {
namespace {

std::atomic<std::uint64_t> g_nextOperationId{1};

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

OperationId OperationId::New() noexcept {
    return OperationId{g_nextOperationId.fetch_add(1, std::memory_order_relaxed)};
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

DiagnosticLog::DiagnosticLog(std::size_t capacity) : capacity_(capacity) {}

void DiagnosticLog::Record(DiagnosticBreadcrumb breadcrumb) {
    std::scoped_lock lock(mutex_);
    if (capacity_ == 0) {
        return;
    }
    if (breadcrumbs_.size() == capacity_) {
        breadcrumbs_.erase(breadcrumbs_.begin());
    }
    breadcrumbs_.push_back(std::move(breadcrumb));
}

std::vector<DiagnosticBreadcrumb> DiagnosticLog::Snapshot() const {
    std::scoped_lock lock(mutex_);
    return breadcrumbs_;
}

}
