#pragma once

#include <AEngine/Foundation/Result.h>
#include <AEngine/Foundation/Time.h>

#include <memory>

namespace aengine {

class ITimeSource {
public:
    virtual ~ITimeSource() = default;

    [[nodiscard]] virtual MonotonicTimePoint Now() const noexcept = 0;
};

[[nodiscard]] Result<std::unique_ptr<ITimeSource>> CreateMonotonicTimeSource();

}
