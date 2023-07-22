cmake_minimum_required(VERSION 3.16)

set(PROJECT Raytracing_GPU)
project(${PROJECT} VERSION 0.0.0 LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(SOURCES
  src/main.cpp
  src/Raytracer.cpp
  src/Vector.cpp
  src/Camera.cpp
  src/Scene.cpp
)

find_package(Qt6 COMPONENTS Gui Widgets REQUIRED)
find_package(OpenCL REQUIRED)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

add_executable(${PROJECT} ${SOURCES})
target_include_directories(${PROJECT} PUBLIC src)
target_link_libraries(${PROJECT} PUBLIC Qt6::Gui Qt6::Widgets OpenCL::OpenCL)
target_compile_features(${PROJECT} PUBLIC cxx_std_17)
