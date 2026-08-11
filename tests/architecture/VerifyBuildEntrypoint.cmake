cmake_minimum_required(VERSION 3.28)

if(NOT DEFINED AENGINE_SOURCE_DIR)
    message(FATAL_ERROR "AENGINE_SOURCE_DIR is required")
endif()

if(NOT EXISTS "${AENGINE_SOURCE_DIR}/build.bat")
    message(FATAL_ERROR "canonical build entrypoint is missing: build.bat")
endif()

file(GLOB workflow_files LIST_DIRECTORIES false
    "${AENGINE_SOURCE_DIR}/.github/workflows/*.yml"
    "${AENGINE_SOURCE_DIR}/.github/workflows/*.yaml")

foreach(workflow_file IN LISTS workflow_files)
    file(READ "${workflow_file}" workflow_content)
    string(TOLOWER "${workflow_content}" normalized_content)

    if(normalized_content MATCHES "(cmake[ \t]+--|ctest|ninja[ .])")
        message(FATAL_ERROR
            "workflow bypasses canonical build.bat entrypoint: ${workflow_file}")
    endif()
endforeach()

set(canonical_workflow "${AENGINE_SOURCE_DIR}/.github/workflows/windows-x64.yml")
if(NOT EXISTS "${canonical_workflow}")
    message(FATAL_ERROR "canonical Windows workflow is missing")
endif()
file(READ "${canonical_workflow}" canonical_content)
string(TOLOWER "${canonical_content}" canonical_normalized)
if(NOT canonical_normalized MATCHES "run:[ \t]*call[ \t]+build\\.bat")
    message(FATAL_ERROR "windows-x64 workflow must invoke build.bat directly")
endif()
