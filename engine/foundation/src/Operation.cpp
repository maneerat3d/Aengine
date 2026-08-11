#include <AEngine/Foundation/Operation.h>

#include <atomic>

namespace aengine {
namespace {

std::atomic<std::uint64_t> g_nextOperationId{1};

}

OperationId OperationId::New() noexcept {
    return OperationId{g_nextOperationId.fetch_add(1, std::memory_order_relaxed)};
}

}
