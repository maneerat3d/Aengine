#include <AEngine/Foundation/Diagnostics.h>

#include <utility>

namespace aengine {

DiagnosticLog::DiagnosticLog(std::size_t capacity) : capacity_(capacity) {}

void DiagnosticLog::Record(DiagnosticBreadcrumb breadcrumb) {
    std::scoped_lock lock(mutex_);
    if (capacity_ == 0) {
        return;
    }
    if (breadcrumbs_.size() == capacity_) {
        breadcrumbs_.erase(breadcrumbs_.begin());
    }
    breadcrumbs_.push_back(std::move(breadcrumb));
}

std::vector<DiagnosticBreadcrumb> DiagnosticLog::Snapshot() const {
    std::scoped_lock lock(mutex_);
    return breadcrumbs_;
}

}
