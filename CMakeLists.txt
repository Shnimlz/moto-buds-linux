cmake_minimum_required(VERSION 3.16)
project(moto-buds VERSION 0.1.0 LANGUAGES CXX)

include(GNUInstallDirs)

# GUI Subdirectory (Qt6 Quick / QML)
add_subdirectory(gui)

# Desktop Entry
install(FILES data/com.motorola.motobuds.desktop
    DESTINATION ${CMAKE_INSTALL_DATADIR}/applications
)

# AppStream Metainfo
install(FILES data/com.motorola.motobuds.metainfo.xml
    DESTINATION ${CMAKE_INSTALL_DATADIR}/metainfo
)

# High-resolution Application Icons
install(FILES assets/icon.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/512x512/apps
    RENAME moto-buds.png
)
install(FILES assets/icon.png
    DESTINATION ${CMAKE_INSTALL_DATADIR}/icons/hicolor/192x192/apps
    RENAME moto-buds.png
)
