if(NOT DEFINED AENGINE_SOURCE_DIR)
    message(FATAL_ERROR "AENGINE_SOURCE_DIR is required")
endif()

file(GLOB_RECURSE public_headers LIST_DIRECTORIES false
    "${AENGINE_SOURCE_DIR}/sdk/include/AEngine/*.h")

foreach(public_header IN LISTS public_headers)
    file(READ "${public_header}" header_content)
    string(TOLOWER "${header_content}" normalized_content)
    if(normalized_content MATCHES "(vulkan|vma|volk|sdl|imgui|flecs|apaint)")
        message(FATAL_ERROR "public header has forbidden dependency: ${public_header}")
    endif()
endforeach()

set(source_roots
    "${AENGINE_SOURCE_DIR}/engine"
    "${AENGINE_SOURCE_DIR}/sdk"
    "${AENGINE_SOURCE_DIR}/tools"
    "${AENGINE_SOURCE_DIR}/tests"
    "${AENGINE_SOURCE_DIR}/CMakeLists.txt"
)

foreach(source_root IN LISTS source_roots)
    if(IS_DIRECTORY "${source_root}")
        file(GLOB_RECURSE source_files LIST_DIRECTORIES false
            "${source_root}/*.h"
            "${source_root}/*.cpp"
            "${source_root}/CMakeLists.txt"
        )
    else()
        set(source_files "${source_root}")
    endif()

    foreach(source_file IN LISTS source_files)
        file(READ "${source_file}" source_content)
        string(TOLOWER "${source_content}" normalized_source)
        if(normalized_source MATCHES "apaint_core|\\.\\./apaint|\\\\apaint|/apaint")
            message(FATAL_ERROR "A-Engine source borrows from APaint: ${source_file}")
        endif()
    endforeach()
endforeach()
