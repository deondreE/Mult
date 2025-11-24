cmake_minimum_required(VERSION 3.20)
project(scompile LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

file(GLOB_RECURSE SRC_FILES
    CONFIGURE_DEPENDS
    "${CMAKE_SOURCE_DIR}/src/*.cpp"
)

add_executable(scompile ${SRC_FILES})

target_include_directories(scompile PRIVATE
    ${CMAKE_SOURCE_DIR}/include
)