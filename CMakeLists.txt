cmake_minimum_required(VERSION 3.28)

project(AEngine VERSION 0.1.0 LANGUAGES CXX)

include(CTest)

if(NOT WIN32)
    message(FATAL_ERROR "A-Engine Phase 1 รองรับ Windows x64 เท่านั้น")
endif()

if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "A-Engine Phase 1 ต้องใช้ target x64")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_subdirectory(engine/foundation)
add_subdirectory(tools/aengine_info)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()
