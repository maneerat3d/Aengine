#pragma once

#include <AEngine/Foundation/Error.h>

#include <cassert>
#include <utility>
#include <variant>

namespace aengine {

template <class T>
class [[nodiscard]] Result {
public:
    [[nodiscard]] static Result Success(T value) {
        return Result(std::in_place_index<0>, std::move(value));
    }

    [[nodiscard]] static Result Failure(Error error) {
        assert(!error.IsSuccess());
        return Result(std::in_place_index<1>, std::move(error));
    }

    [[nodiscard]] bool HasValue() const noexcept { return value_.index() == 0; }
    [[nodiscard]] explicit operator bool() const noexcept { return HasValue(); }

    [[nodiscard]] T& Value() & {
        assert(HasValue());
        return std::get<0>(value_);
    }

    [[nodiscard]] const T& Value() const& {
        assert(HasValue());
        return std::get<0>(value_);
    }

    [[nodiscard]] T&& Value() && {
        assert(HasValue());
        return std::move(std::get<0>(value_));
    }

    [[nodiscard]] const aengine::Error& Error() const& {
        assert(!HasValue());
        return std::get<1>(value_);
    }

private:
    template <class... Args>
    explicit Result(std::in_place_index_t<0> index, Args&&... args)
        : value_(index, std::forward<Args>(args)...) {}

    template <class... Args>
    explicit Result(std::in_place_index_t<1> index, Args&&... args)
        : value_(index, std::forward<Args>(args)...) {}

    std::variant<T, aengine::Error> value_;
};

template <>
class [[nodiscard]] Result<void> {
public:
    [[nodiscard]] static Result Success() { return Result(true, {}); }

    [[nodiscard]] static Result Failure(Error error) {
        assert(!error.IsSuccess());
        return Result(false, std::move(error));
    }

    [[nodiscard]] bool HasValue() const noexcept { return success_; }
    [[nodiscard]] explicit operator bool() const noexcept { return HasValue(); }

    [[nodiscard]] const aengine::Error& Error() const& {
        assert(!HasValue());
        return error_;
    }

private:
    Result(bool success, aengine::Error error)
        : success_(success), error_(std::move(error)) {}

    bool success_ = false;
    aengine::Error error_{};
};

}
