#include "ApplicationCompositionRoot.h"

#include <AEngine/Foundation/Error.h>

namespace aengine::detail {

Result<ApplicationRuntime> ComposeApplication(const AppConfig& config) {
    if (config.name.data == nullptr || config.name.size == 0) {
        return Result<ApplicationRuntime>::Failure(MakeError(
            ErrorCode::InvalidArgument,
            "AppConfig.name must not be empty",
            "aengine_platform"));
    }

    return Result<ApplicationRuntime>::Success(ApplicationRuntime{});
}

}
