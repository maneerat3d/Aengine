#pragma once

#include "ApplicationRuntime.h"

#include <AEngine/Application/AppConfig.h>
#include <AEngine/Foundation/Result.h>

namespace aengine::detail {

[[nodiscard]] Result<ApplicationRuntime> ComposeApplication(const AppConfig& config);

}
