#include <AEngine/Foundation.h>

#include <iostream>

int main() {
    const auto identity = aengine::GetBuildIdentity();
    const auto capabilities = aengine::GetCapabilities();

    std::cout << "aengine_info\n";
    std::cout << "api=" << identity.apiVersion.major << '.' << identity.apiVersion.minor << '.'
              << identity.apiVersion.patch << '\n';
    std::cout << "configuration=" << identity.configuration << '\n';
    std::cout << "compiler=" << identity.compiler << '\n';
    std::cout << "capabilities=" << capabilities.Bits() << '\n';
    return capabilities.Supports(aengine::Capability::Foundation) &&
                   capabilities.Supports(aengine::Capability::Headless)
               ? 0
               : 1;
}
