add_library(aengine_foundation STATIC
    src/Diagnostics.cpp
    src/Operation.cpp
    src/Version.cpp
)

add_library(AEngine::Foundation ALIAS aengine_foundation)

target_include_directories(aengine_foundation
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/sdk/include>
)

target_compile_features(aengine_foundation PUBLIC cxx_std_20)

target_compile_definitions(aengine_foundation
    PRIVATE
        AENGINE_BUILD_CONFIGURATION="$<CONFIG>"
)

get_target_property(_aengine_foundation_links aengine_foundation LINK_LIBRARIES)
if(_aengine_foundation_links AND NOT _aengine_foundation_links STREQUAL "_aengine_foundation_links-NOTFOUND")
    message(FATAL_ERROR "aengine_foundation ต้องไม่ link dependency ภายนอก")
endif()
