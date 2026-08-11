#pragma once

#include <AEngine/Foundation/Handle.h>
#include <AEngine/Foundation/Result.h>

#include <cstdint>
#include <limits>
#include <optional>
#include <utility>
#include <vector>

namespace aengine {

template <class Tag, class T>
class HandlePool {
public:
    [[nodiscard]] Result<Handle<Tag>> Insert(T value) {
        if (!freeSlots_.empty()) {
            const auto slotIndex = freeSlots_.back();
            freeSlots_.pop_back();
            auto& slot = slots_[slotIndex];
            slot.value.emplace(std::move(value));
            return Result<Handle<Tag>>::Success(Handle<Tag>{slotIndex, slot.generation});
        }

        if (slots_.size() == std::numeric_limits<std::uint32_t>::max()) {
            return Result<Handle<Tag>>::Failure(MakeError(
                ErrorCode::ResourceExhausted, "handle pool slot limit reached", "HandlePool"));
        }

        slots_.push_back(Slot{.value = std::move(value), .generation = 1});
        const auto slotIndex = static_cast<std::uint32_t>(slots_.size() - 1);
        return Result<Handle<Tag>>::Success(Handle<Tag>{slotIndex, 1});
    }

    [[nodiscard]] Result<T*> Get(Handle<Tag> handle) {
        auto validated = Validate(handle);
        if (!validated) {
            return Result<T*>::Failure(validated.Error());
        }
        return Result<T*>::Success(&*slots_[handle.slot].value);
    }

    [[nodiscard]] Result<const T*> Get(Handle<Tag> handle) const {
        auto validated = Validate(handle);
        if (!validated) {
            return Result<const T*>::Failure(validated.Error());
        }
        return Result<const T*>::Success(&*slots_[handle.slot].value);
    }

    [[nodiscard]] Result<void> Erase(Handle<Tag> handle) {
        auto validated = Validate(handle);
        if (!validated) {
            return validated;
        }

        auto& slot = slots_[handle.slot];
        slot.value.reset();
        slot.generation = NextGeneration(slot.generation);
        freeSlots_.push_back(handle.slot);
        return Result<void>::Success();
    }

private:
    struct Slot {
        std::optional<T> value;
        std::uint32_t generation = 1;
    };

    [[nodiscard]] Result<void> Validate(Handle<Tag> handle) const {
        if (!handle.IsValid()) {
            return Result<void>::Failure(
                MakeError(ErrorCode::InvalidArgument, "invalid handle", "HandlePool"));
        }
        if (handle.slot >= slots_.size()) {
            return Result<void>::Failure(
                MakeError(ErrorCode::StaleHandle, "handle slot is unavailable", "HandlePool"));
        }

        const auto& slot = slots_[handle.slot];
        if (!slot.value.has_value() || slot.generation != handle.generation) {
            return Result<void>::Failure(
                MakeError(ErrorCode::StaleHandle, "handle generation is stale", "HandlePool"));
        }
        return Result<void>::Success();
    }

    [[nodiscard]] static constexpr std::uint32_t NextGeneration(std::uint32_t generation) noexcept {
        return generation == std::numeric_limits<std::uint32_t>::max() ? 1 : generation + 1;
    }

    std::vector<Slot> slots_;
    std::vector<std::uint32_t> freeSlots_;
};

}
