#include "ApplicationCompositionRoot.h"

#include "ApplicationPlatformServices.h"
#include "FixedStepTimePort.h"

#include <AEngine/Foundation/Error.h>

#include <cstdint>
#include <memory>
#include <new>
#include <utility>

namespace aengine::detail {

namespace {
constexpr std::uint64_t kHeadlessFrameStepNanoseconds = 16'666'667;
constexpr const char* kOwner = "aengine_platform";
}

Result<ApplicationRuntime> ComposeApplication(const AppConfig& config) {
    if (config.name.data == nullptr || config.name.size == 0) {
        return Result<ApplicationRuntime>::Failure(MakeError(
            ErrorCode::InvalidArgument,
            "AppConfig.name must not be empty",
            kOwner));
    }

    std::unique_ptr<TimePort> timePort{
        new (std::nothrow) FixedStepTimePort{kHeadlessFrameStepNanoseconds}};
    if (!timePort) {
        return Result<ApplicationRuntime>::Failure(MakeError(
            ErrorCode::ResourceExhausted,
            "failed to allocate application time port",
            kOwner));
    }

    ApplicationPlatformServices services{std::move(timePort)};
    return Result<ApplicationRuntime>::Success(
        ApplicationRuntime{std::move(services)});
}

}
