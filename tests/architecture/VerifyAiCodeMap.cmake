cmake_minimum_required(VERSION 3.28)

if(NOT DEFINED AENGINE_SOURCE_DIR)
    message(FATAL_ERROR "AENGINE_SOURCE_DIR is required")
endif()

set(generator "${AENGINE_SOURCE_DIR}/tools/ai_map/UpdateAiCodeMap.ps1")
if(NOT EXISTS "${generator}")
    message(FATAL_ERROR "AI code map generator is missing: ${generator}")
endif()

execute_process(
    COMMAND powershell.exe
        -NoProfile
        -ExecutionPolicy Bypass
        -File "${generator}"
        -RepoRoot "${AENGINE_SOURCE_DIR}"
        -Mode Check
    WORKING_DIRECTORY "${AENGINE_SOURCE_DIR}"
    RESULT_VARIABLE result
    OUTPUT_VARIABLE output
    ERROR_VARIABLE error_output
)

if(NOT result EQUAL 0)
    message(FATAL_ERROR
        "AI code map drift/validation failed (exit ${result})\n${output}\n${error_output}")
endif()

message(STATUS "${output}")
