#pragma once

#include <AEngine/Foundation/Result.h>

#include <cstdint>
#include <memory>

namespace aengine {

struct MonotonicTimePoint {
    std::int64_t nanoseconds = 0;
};

class ITimeSource {
public:
    virtual ~ITimeSource() = default;

    [[nodiscard]] virtual MonotonicTimePoint Now() const noexcept = 0;
};

[[nodiscard]] Result<std::unique_ptr<ITimeSource>> CreateMonotonicTimeSource();

}
