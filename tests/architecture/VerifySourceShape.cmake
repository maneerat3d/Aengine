cmake_minimum_required(VERSION 3.28)

if(NOT DEFINED AENGINE_SOURCE_DIR)
    message(FATAL_ERROR "AENGINE_SOURCE_DIR is required")
endif()

function(aengine_check_source_shape file_path max_lines scope_name)
    if(NOT EXISTS "${file_path}")
        return()
    endif()

    file(STRINGS "${file_path}" source_lines)
    list(LENGTH source_lines line_count)

    if(line_count GREATER max_lines)
        file(RELATIVE_PATH relative_path "${AENGINE_SOURCE_DIR}" "${file_path}")
        message(FATAL_ERROR
            "${scope_name} exceeds source-shape budget: ${relative_path} has ${line_count} lines; max is ${max_lines}. Split by responsibility before adding more code.")
    endif()
endfunction()

file(GLOB_RECURSE public_headers LIST_DIRECTORIES false
    "${AENGINE_SOURCE_DIR}/sdk/include/AEngine/*.h")
foreach(file_path IN LISTS public_headers)
    aengine_check_source_shape("${file_path}" 220 "public SDK header")
endforeach()

file(GLOB_RECURSE engine_sources LIST_DIRECTORIES false
    "${AENGINE_SOURCE_DIR}/engine/*.h"
    "${AENGINE_SOURCE_DIR}/engine/*.cpp")
foreach(file_path IN LISTS engine_sources)
    aengine_check_source_shape("${file_path}" 320 "engine source")
endforeach()

file(GLOB_RECURSE tool_sources LIST_DIRECTORIES false
    "${AENGINE_SOURCE_DIR}/tools/*.h"
    "${AENGINE_SOURCE_DIR}/tools/*.cpp")
foreach(file_path IN LISTS tool_sources)
    aengine_check_source_shape("${file_path}" 240 "tool source")
endforeach()

file(GLOB_RECURSE automation_scripts LIST_DIRECTORIES false
    "${AENGINE_SOURCE_DIR}/tools/*.ps1"
    "${AENGINE_SOURCE_DIR}/tools/*.psm1")
foreach(file_path IN LISTS automation_scripts)
    aengine_check_source_shape("${file_path}" 260 "automation script")
endforeach()
aengine_check_source_shape("${AENGINE_SOURCE_DIR}/build.bat" 220 "canonical build script")

file(GLOB_RECURSE module_manifests LIST_DIRECTORIES false
    "${AENGINE_SOURCE_DIR}/engine/*/MODULE.json"
    "${AENGINE_SOURCE_DIR}/tools/*/MODULE.json")
foreach(file_path IN LISTS module_manifests)
    aengine_check_source_shape("${file_path}" 120 "module manifest")
endforeach()

file(GLOB_RECURSE test_sources LIST_DIRECTORIES false
    "${AENGINE_SOURCE_DIR}/tests/*.h"
    "${AENGINE_SOURCE_DIR}/tests/*.cpp")
foreach(file_path IN LISTS test_sources)
    aengine_check_source_shape("${file_path}" 400 "test source")
endforeach()

file(GLOB_RECURSE module_cmake_files LIST_DIRECTORIES false
    "${AENGINE_SOURCE_DIR}/engine/*/CMakeLists.txt"
    "${AENGINE_SOURCE_DIR}/tools/*/CMakeLists.txt"
    "${AENGINE_SOURCE_DIR}/tests/architecture/*.cmake")
list(APPEND module_cmake_files
    "${AENGINE_SOURCE_DIR}/CMakeLists.txt"
    "${AENGINE_SOURCE_DIR}/tests/CMakeLists.txt")
foreach(file_path IN LISTS module_cmake_files)
    aengine_check_source_shape("${file_path}" 300 "build/architecture script")
endforeach()

set(ai_map_root "${AENGINE_SOURCE_DIR}/.agent/code-map/current")
aengine_check_source_shape("${ai_map_root}/AI_CONTEXT.md" 200 "AI context index")
aengine_check_source_shape("${ai_map_root}/INDEX.json" 220 "AI module index")
file(GLOB ai_module_maps LIST_DIRECTORIES false "${ai_map_root}/modules/*.json")
foreach(file_path IN LISTS ai_module_maps)
    aengine_check_source_shape("${file_path}" 300 "AI module map")
endforeach()
