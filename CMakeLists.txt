cmake_minimum_required (VERSION 2.6)
project(rainbow-lollipop C)

list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_SOURCE_DIR}/cmake/vala
)

include(vala_precompile)
include(ValaVersion)

find_package(Vala REQUIRED)
vala_precompile()

