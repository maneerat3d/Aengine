#pragma once

#include <AEngine/Foundation/Error.h>

#include <cstddef>
#include <mutex>
#include <string>
#include <vector>

namespace aengine {

struct DiagnosticBreadcrumb {
    OperationId operationId{};
    std::string owner;
    std::string message;
};

class DiagnosticLog {
public:
    explicit DiagnosticLog(std::size_t capacity = 64);

    void Record(DiagnosticBreadcrumb breadcrumb);
    [[nodiscard]] std::vector<DiagnosticBreadcrumb> Snapshot() const;

private:
    std::size_t capacity_;
    mutable std::mutex mutex_;
    std::vector<DiagnosticBreadcrumb> breadcrumbs_;
};

}
