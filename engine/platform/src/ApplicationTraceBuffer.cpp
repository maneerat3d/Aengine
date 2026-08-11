#include "ApplicationTraceBuffer.h"

namespace aengine::detail {

void ApplicationTraceBuffer::Record(ApplicationTraceEvent event,
                                    std::uint64_t frameIndex) noexcept {
    const auto sequence = nextSequence_++;
    if (size_ >= entries_.size()) {
        truncated_ = true;
        return;
    }

    entries_[size_++] = ApplicationTraceEntry{
        .sequence = sequence,
        .frameIndex = frameIndex,
        .event = event,
    };
}

ApplicationTraceView ApplicationTraceBuffer::View() const noexcept {
    return ApplicationTraceView{
        .data = entries_.data(),
        .size = size_,
        .truncated = truncated_,
    };
}

}
