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

pkg_check_modules(GLIB REQUIRED glib-2.0)
add_definitions(${GLIB_CFLAGS} ${GLIB_CFLAGS_OTHER})
link_libraries(${GLIB_LIBRARIES})
link_directories(${GLIB_LIBRARY_DIRS})

pkg_check_modules(GTK REQUIRED gtk+-3.0)
add_definitions(${GTK_CFLAGS} ${GTK_CFLAGS_OTHER})
link_libraries(${GTK_LIBRARIES})
link_directories(${GTK_LIBRARY_DIRS})

pkg_check_modules(CLUTTER REQUIRED clutter-1.0)
add_definitions(${CLUTTER_CFLAGS} ${CLUTTER_CFLAGS_OTHER})
link_libraries(${CLUTTER_LIBRARIES})
link_directories(${CLUTTER_LIBRARY_DIRS})

pkg_check_modules(CLUTTERGTK REQUIRED clutter-gtk-1.0)
add_definitions(${CLUTTERGTK_CFLAGS} ${CLUTTERGTK_CFLAGS_OTHER})
link_libraries(${CLUTTERGTK_LIBRARIES})
link_directories(${CLUTTERGTK_LIBRARY_DIRS})

pkg_check_modules(GEE REQUIRED gee-1.0)
add_definitions(${GEE_CFLAGS} ${GEE_CFLAGS_OTHER})
link_libraries(${GEE_LIBRARIES})
link_directories(${GEE_LIBRARY_DIRS})

pkg_check_modules(WEBKIT REQUIRED webkit2gtk-4.0)
add_definitions(${WEBKIT_CFLAGS} ${WEBKIT_CFLAGS_OTHER})
link_libraries(${WEBKIT_LIBRARIES})
link_directories(${WEBKIT_LIBRARY_DIRS})

pkg_check_modules(WEBKIT_EXT REQUIRED webkit2gtk-web-extension-4.0)
add_definitions(${WEBKIT_EXT_CFLAGS} ${WEBKIT_EXT_CFLAGS_OTHER})
link_libraries(${WEBKIT_EXT_LIBRARIES})
link_directories(${WEBKIT_EXT_LIBRARY_DIRS})

pkg_check_modules(SQLITE3 REQUIRED sqlite3)
add_definitions(${SQLITE3_CFLAGS} ${SQLITE3_CFLAGS_OTHER})
link_libraries(${SQLITE3_LIBRARIES})
link_directories(${SQLITE3_LIBRARY_DIRS})

pkg_check_modules(ZMQ REQUIRED libzmq)
add_definitions(${ZMQ_CFLAGS} ${ZMQ_CFLAGS_OTHER})
link_libraries(${ZMQ_LIBRARIES})
link_directories(${ZMQ_LIBRARY_DIRS})

vala_precompile(VALA_BINARY_C
    "src/dummy.vala"
    "src/track.vala"
    "src/database.vala"
    "src/empty_track.vala"
    "src/alaia.vala"
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
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

vala_precompile(VALA_EXTENSION_C
    "src/dummy2.vala"
    "src/alaia_extension.vala"
PACKAGES
    webkit2gtk-web-extension-4.0
    libzmq
    gee-1.0
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

add_library("alaiaextension" SHARED ${VALA_EXTENSION_C})
add_executable(${PROJECT_NAME} ${VALA_BINARY_C})

install(FILES "cfg/config.json" DESTINATION /etc/${PROJECT_NAME})
install(DIRECTORY "data/rainbow-lollipop" DESTINATION share)
install(DIRECTORY "data/icons" DESTINATION share)
install(DIRECTORY "data/applications" DESTINATION share)
install(TARGETS "alaiaextension" ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib/${PROJECT_NAME}
)
