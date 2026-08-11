add_executable(aengine_foundation_contract_tests
    contract/FoundationContractTests.cpp
)
target_link_libraries(aengine_foundation_contract_tests PRIVATE AEngine::Foundation)
target_compile_features(aengine_foundation_contract_tests PRIVATE cxx_std_20)

add_library(aengine_header_self_containment OBJECT
    headers/AbiHeader.cpp
    headers/DiagnosticsHeader.cpp
    headers/ErrorHeader.cpp
    headers/HandleHeader.cpp
    headers/HandlePoolHeader.cpp
    headers/JobHeader.cpp
    headers/OperationHeader.cpp
    headers/ResultHeader.cpp
    headers/VersionHeader.cpp
    headers/FoundationHeader.cpp
)
target_link_libraries(aengine_header_self_containment PRIVATE AEngine::Foundation)
target_compile_features(aengine_header_self_containment PRIVATE cxx_std_20)

add_test(NAME aengine.foundation.contract COMMAND aengine_foundation_contract_tests)
set_tests_properties(aengine.foundation.contract PROPERTIES LABELS "contract;foundation")

add_test(
    NAME aengine.architecture.guard
    COMMAND ${CMAKE_COMMAND}
        -DAENGINE_SOURCE_DIR=${PROJECT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/architecture/VerifyArchitecture.cmake
)
set_tests_properties(aengine.architecture.guard PROPERTIES LABELS "architecture;foundation")

add_test(
    NAME aengine.architecture.source_shape
    COMMAND ${CMAKE_COMMAND}
        -DAENGINE_SOURCE_DIR=${PROJECT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/architecture/VerifySourceShape.cmake
)
set_tests_properties(aengine.architecture.source_shape PROPERTIES
    LABELS "architecture;source-shape;foundation"
)

add_test(
    NAME aengine.architecture.agent_skills
    COMMAND ${CMAKE_COMMAND}
        -DAENGINE_SOURCE_DIR=${PROJECT_SOURCE_DIR}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/architecture/VerifyAgentSkills.cmake
)
set_tests_properties(aengine.architecture.agent_skills PROPERTIES
    LABELS "architecture;agent-skills;foundation"
)

add_test(
    NAME aengine.info
    COMMAND aengine_info
)
set_tests_properties(aengine.info PROPERTIES
    LABELS "consumer;foundation"
    PASS_REGULAR_EXPRESSION "api=0\\.1\\.0"
)
