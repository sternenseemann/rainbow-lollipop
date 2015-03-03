cmake_minimum_required (VERSION 2.6)
project(rainbow-lollipop C)

list(APPEND CMAKE_MODULE_PATH
    ${CMAKE_SOURCE_DIR}/cmake/vala
)

include(ValaPrecompile)
include(ValaVersion)

find_package(Vala REQUIRED)
ensure_vala_version("0.26" MINIMUM)

find_package(PkgConfig)
pkg_check_modules(GTK REQUIRED gtk+-3.0)

pkg_check_modules(CLUTTER REQUIRED clutter-1.0)
pkg_check_modules(CLUTTERGTK REQUIRED clutter-gtk-1.0)
pkg_check_modules(GEE REQUIRED gee-1.0)
pkg_check_modules(WEBKIT REQUIRED webkit2gtk-4.0)
pkg_check_modules(SQLITE3 REQUIRED sqlite3)
pkg_check_modules(ZMQ REQUIRED libzmq)

vala_precompile(VALA_C
    "src/alaia.vala"
    "src/track.vala"
    "src/empty_track.vala"
    "src/history_track.vala"
    "src/tracklist.vala" 
    "src/nodes.vala"
    "src/site_node.vala"
    "src/download_node.vala"
    "src/config.vala"
    "src/ipc.vala"
    "src/session_select.vala"
    "src/authentication_dialog.vala"
    "src/history.vala"
    "src/searchengine.vala"
PACKAGES
    gtk+-3.0
    clutter-1.0
    clutter-gtk-1.0
    webkit2gtk-4.0
    gee-1.0
    libzmq 
    sqlite3
OPTIONS
    --thread
)

add_executable("rainbow-lollipop" ${VALA_C})

