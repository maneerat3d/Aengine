#include <AEngine/Foundation.h>

#include <cstdint>
#include <cstdlib>
#include <iostream>
#include <string>
#include <type_traits>

namespace {

struct DocumentTag;
struct LayerTag;

using DocumentHandle = aengine::Handle<DocumentTag>;
using LayerHandle = aengine::Handle<LayerTag>;

static_assert(!std::is_convertible_v<DocumentHandle, LayerHandle>);
static_assert(std::is_trivially_copyable_v<aengine::MonotonicTimePoint>);
static_assert(sizeof(aengine::MonotonicTimePoint) == sizeof(std::int64_t));

void Require(bool condition, const char* message) {
    if (!condition) {
        std::cerr << "FAILED: " << message << '\n';
        std::exit(1);
    }
}

void TestHandleGeneration() {
    aengine::HandlePool<DocumentTag, std::string> documents;
    const auto created = documents.Insert("first");
    Require(static_cast<bool>(created), "handle creation must succeed");

    const auto handle = created.Value();
    Require(handle.IsValid(), "created handle must be valid");
    Require(static_cast<bool>(documents.Get(handle)), "live handle must resolve");
    Require(static_cast<bool>(documents.Erase(handle)), "handle erase must succeed");

    const auto stale = documents.Get(handle);
    Require(!stale, "erased handle must fail");
    Require(stale.Error().code == aengine::ErrorCode::StaleHandle,
            "erased handle must report StaleHandle");
    Require(stale.Error().owner == "HandlePool", "stale handle must identify its owner");
    Require(stale.Error().operationId.IsValid(), "stale handle error must carry operation ID");

    const auto forged = documents.Get(DocumentHandle{.slot = 42, .generation = 1});
    Require(!forged, "forged handle must fail");
    Require(forged.Error().code == aengine::ErrorCode::StaleHandle,
            "forged handle must report StaleHandle");

    const auto replacement = documents.Insert("second");
    Require(static_cast<bool>(replacement), "replacement handle creation must succeed");
    Require(replacement.Value().slot == handle.slot, "released slot must be reusable");
    Require(replacement.Value().generation != handle.generation,
            "reused slot must advance generation");
}

void TestResultAndOperationContracts() {
    const auto operation = aengine::OperationId::New();
    Require(operation.IsValid(), "generated operation ID must be valid");

    const auto failed = aengine::Result<int>::Failure(aengine::MakeError(
        aengine::ErrorCode::Unsupported, "not enabled", "FoundationContractTests", operation));
    Require(!failed, "error result must not contain a value");
    Require(failed.Error().code == aengine::ErrorCode::Unsupported,
            "error code must be preserved");
    Require(failed.Error().owner == "FoundationContractTests", "error owner must be preserved");
    Require(failed.Error().operationId == operation, "error operation ID must be preserved");

    const auto succeeded = aengine::Result<void>::Success();
    Require(static_cast<bool>(succeeded), "void success result must contain a value");
}

void TestTimeMetadata() {
    constexpr aengine::MonotonicTimePoint timestamp{42};
    Require(timestamp.nanoseconds == 42,
            "monotonic time metadata must preserve fixed-width nanoseconds");
}

void TestCapabilitiesAndJobValues() {
    const auto capabilities = aengine::GetCapabilities();
    Require(capabilities.Supports(aengine::Capability::Foundation),
            "foundation capability must be reported");
    Require(capabilities.Supports(aengine::Capability::Headless),
            "headless capability must be reported");

    const aengine::JobStatus queued{};
    Require(queued.state == aengine::JobState::Queued, "job status must default to queued");
    Require(queued.error.IsSuccess(), "queued job must not carry an error");
}

void TestDiagnostics() {
    aengine::DiagnosticLog log(2);
    log.Record({.operationId = aengine::OperationId::New(), .owner = "first", .message = "one"});
    log.Record({.operationId = aengine::OperationId::New(), .owner = "second", .message = "two"});
    log.Record({.operationId = aengine::OperationId::New(), .owner = "third", .message = "three"});

    const auto breadcrumbs = log.Snapshot();
    Require(breadcrumbs.size() == 2, "diagnostics must retain configured breadcrumb capacity");
    Require(breadcrumbs.front().owner == "second", "diagnostics must discard the oldest breadcrumb");
    Require(breadcrumbs.back().owner == "third", "diagnostics must retain the newest breadcrumb");
}

}

int main() {
    TestHandleGeneration();
    TestResultAndOperationContracts();
    TestTimeMetadata();
    TestCapabilitiesAndJobValues();
    TestDiagnostics();
    return 0;
}
