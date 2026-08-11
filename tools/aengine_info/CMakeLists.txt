add_executable(aengine_info main.cpp)
target_link_libraries(aengine_info PRIVATE AEngine::Foundation)
target_compile_features(aengine_info PRIVATE cxx_std_20)
