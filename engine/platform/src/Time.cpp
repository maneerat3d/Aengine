#include <AEngine/Platform/Time.h>

#include <AEngine/Foundation/Error.h>

#include <chrono>
#include <new>
#include <utility>

namespace aengine {

namespace {

class SteadyTimeSource final : public ITimeSource {
public:
    [[nodiscard]] MonotonicTimePoint Now() const noexcept override {
        const auto elapsed = std::chrono::duration_cast<std::chrono::nanoseconds>(
            std::chrono::steady_clock::now().time_since_epoch());
        return MonotonicTimePoint{static_cast<std::int64_t>(elapsed.count())};
    }
};

}

Result<std::unique_ptr<ITimeSource>> CreateMonotonicTimeSource() {
    auto* source = new (std::nothrow) SteadyTimeSource{};
    if (source == nullptr) {
        return Result<std::unique_ptr<ITimeSource>>::Failure(MakeError(
            ErrorCode::ResourceExhausted,
            "failed to allocate monotonic time source",
            "aengine_platform"));
    }

    return Result<std::unique_ptr<ITimeSource>>::Success(
        std::unique_ptr<ITimeSource>{source});
}

}
