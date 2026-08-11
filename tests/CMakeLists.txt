add_executable(aengine_foundation_contract_tests
    contract/FoundationContractTests.cpp
)
target_link_libraries(aengine_foundation_contract_tests PRIVATE AEngine::Foundation)
target_compile_features(aengine_foundation_contract_tests PRIVATE cxx_std_20)

add_executable(aengine_platform_contract_tests
    contract/ApplicationContractTests.cpp
)
target_link_libraries(aengine_platform_contract_tests PRIVATE AEngine::Platform)
target_compile_features(aengine_platform_contract_tests PRIVATE cxx_std_20)

add_library(aengine_header_self_containment OBJECT
    headers/AbiHeader.cpp
    headers/AppConfigHeader.cpp
    headers/AppHeader.cpp
    headers/ApplicationHeader.cpp
    headers/ApplicationStateHeader.cpp
    headers/ApplicationTraceHeader.cpp
    headers/DiagnosticsHeader.cpp
    headers/ErrorHeader.cpp
    headers/FoundationTimeHeader.cpp
    headers/HandleHeader.cpp
    headers/HandlePoolHeader.cpp
    headers/JobHeader.cpp
    headers/OperationHeader.cpp
    headers/ResultHeader.cpp
    headers/TimeHeader.cpp
    headers/VersionHeader.cpp
    headers/FoundationHeader.cpp
)
target_link_libraries(aengine_header_self_containment PRIVATE AEngine::Foundation)
target_compile_features(aengine_header_self_containment PRIVATE cxx_std_20)

add_test(NAME aengine.foundation.contract COMMAND aengine_foundation_contract_tests)
set_tests_properties(aengine.foundation.contract PROPERTIES LABELS "contract;foundation")

add_test(NAME aengine.platform.contract COMMAND aengine_platform_contract_tests)
set_tests_properties(aengine.platform.contract PROPERTIES LABELS "contract;platform")

add_test(
    NAME aengine.architecture.guard
    COMMAND ${CMAKE_COMMAND}
        -DAENGINE_SOURCE_DIR=${PROJECT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/architecture/VerifyArchitecture.cmake
)
set_tests_properties(aengine.architecture.guard PROPERTIES LABELS "architecture;foundation;platform")

add_test(
    NAME aengine.architecture.source_shape
    COMMAND ${CMAKE_COMMAND}
        -DAENGINE_SOURCE_DIR=${PROJECT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/architecture/VerifySourceShape.cmake
)
set_tests_properties(aengine.architecture.source_shape PROPERTIES
    LABELS "architecture;source-shape;foundation;platform"
)

add_test(
    NAME aengine.architecture.agent_skills
    COMMAND ${CMAKE_COMMAND}
        -DAENGINE_SOURCE_DIR=${PROJECT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/architecture/VerifyAgentSkills.cmake
)
set_tests_properties(aengine.architecture.agent_skills PROPERTIES
    LABELS "architecture;agent-skills;foundation;platform"
)

add_test(
    NAME aengine.architecture.build_entrypoint
    COMMAND ${CMAKE_COMMAND}
        -DAENGINE_SOURCE_DIR=${PROJECT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/architecture/VerifyBuildEntrypoint.cmake
)
set_tests_properties(aengine.architecture.build_entrypoint PROPERTIES
    LABELS "architecture;build-entrypoint;foundation;platform"
)

add_test(
    NAME aengine.architecture.ai_code_map
    COMMAND ${CMAKE_COMMAND}
        -DAENGINE_SOURCE_DIR=${PROJECT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/architecture/VerifyAiCodeMap.cmake
)
set_tests_properties(aengine.architecture.ai_code_map PROPERTIES
    LABELS "architecture;ai-code-map;foundation;platform"
)

set(aengine_safety_tool_root "${PROJECT_SOURCE_DIR}/tools/architecture_safety")

add_test(
    NAME aengine.architecture.module_contract
    COMMAND powershell.exe -NoProfile -ExecutionPolicy Bypass
        -File "${aengine_safety_tool_root}/VerifyModuleContracts.ps1"
        -RepoRoot "${PROJECT_SOURCE_DIR}"
)
set_tests_properties(aengine.architecture.module_contract PROPERTIES
    LABELS "architecture;safety;module-contract;foundation;platform"
)

add_test(
    NAME aengine.architecture.dependency_cycle
    COMMAND powershell.exe -NoProfile -ExecutionPolicy Bypass
        -File "${aengine_safety_tool_root}/VerifyDependencyGraph.ps1"
        -RepoRoot "${PROJECT_SOURCE_DIR}"
)
set_tests_properties(aengine.architecture.dependency_cycle PROPERTIES
    LABELS "architecture;safety;dependency;foundation;platform"
)

add_test(
    NAME aengine.architecture.public_api_ownership
    COMMAND powershell.exe -NoProfile -ExecutionPolicy Bypass
        -File "${aengine_safety_tool_root}/VerifyPublicApiOwnership.ps1"
        -RepoRoot "${PROJECT_SOURCE_DIR}"
)
set_tests_properties(aengine.architecture.public_api_ownership PROPERTIES
    LABELS "architecture;safety;public-api;foundation;platform"
)

add_test(
    NAME aengine.architecture.oop_policy
    COMMAND powershell.exe -NoProfile -ExecutionPolicy Bypass
        -File "${aengine_safety_tool_root}/VerifyOopPolicy.ps1"
        -RepoRoot "${PROJECT_SOURCE_DIR}"
)
set_tests_properties(aengine.architecture.oop_policy PROPERTIES
    LABELS "architecture;safety;oop;foundation;platform"
)

add_test(
    NAME aengine.info
    COMMAND aengine_info
)
set_tests_properties(aengine.info PROPERTIES
    LABELS "consumer;foundation"
    PASS_REGULAR_EXPRESSION "api=0\\.1\\.0"
)

add_test(
    NAME aengine.headless
    COMMAND aengine_headless
)
set_tests_properties(aengine.headless PROPERTIES
    LABELS "consumer;platform;headless"
    PASS_REGULAR_EXPRESSION "frames=3 state=stopped"
)
