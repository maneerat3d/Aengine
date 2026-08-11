#pragma once

#include <cstdint>

namespace aengine {

enum class ApplicationState : std::uint8_t {
    Running = 0,
    QuitRequested,
    Stopped,
};

}
