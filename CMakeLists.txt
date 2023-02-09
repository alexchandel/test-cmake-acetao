cmake_minimum_required(VERSION 3.24)

project(
    TrivialTest
    VERSION 1.0
    LANGUAGES CXX
)



list(APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_LIST_DIR}/cmake)
set(ACE_ROOT "${CMAKE_CURRENT_LIST_DIR}/ACE_wrappers")
include(init)
include(idl_files)



set(CMAKE_CXX_STANDARD 11)
# add_subdirectory(ACE_wrappers EXCLUDE_FROM_ALL)
add_subdirectory(ACE_wrappers/TAO EXCLUDE_FROM_ALL)



add_executable(TrivialTest main.cpp)
add_dependencies(TrivialTest ACE)
