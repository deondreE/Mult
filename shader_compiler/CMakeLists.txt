cmake_minimum_required(VERSION 3.15)
project(ShaderCompiler LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(ShaderCompiler src/main.cpp)