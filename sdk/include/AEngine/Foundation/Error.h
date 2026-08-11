#pragma once

#include <AEngine/Foundation/Operation.h>

#include <cstdint>
#include <string>
#include <utility>

namespace aengine {

enum class ErrorCode : std::uint32_t {
    Ok = 0,
    InvalidArgument,
    InvalidState,
    NotFound,
    StaleHandle,
    Unsupported,
    PermissionDenied,
    Busy,
    Cancelled,
    BackendUnavailable,
    ResourceExhausted,
    IoFailure,
    InternalFailure,
};

struct Error {
    ErrorCode code = ErrorCode::Ok;
    OperationId operationId{};
    std::string message;
    std::string owner;
    bool retryable = false;

    [[nodiscard]] constexpr bool IsSuccess() const noexcept {
        return code == ErrorCode::Ok;
    }
};

[[nodiscard]] inline Error MakeError(ErrorCode code, std::string message,
                                     std::string owner,
                                     OperationId operationId = OperationId::New(),
                                     bool retryable = false) {
    return Error{
        .code = code,
        .operationId = operationId,
        .message = std::move(message),
        .owner = std::move(owner),
        .retryable = retryable,
    };
}

}
