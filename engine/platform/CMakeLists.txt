add_library(aengine_platform STATIC
    src/App.cpp
    src/ApplicationCompositionRoot.cpp
    src/ApplicationLifecycle.cpp
    src/ApplicationRuntime.cpp
    src/ApplicationTraceBuffer.cpp
)

add_library(AEngine::Platform ALIAS aengine_platform)

target_include_directories(aengine_platform
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/sdk/include>
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(aengine_platform PUBLIC AEngine::Foundation)
target_compile_features(aengine_platform PUBLIC cxx_std_20)
