cmake_minimum_required(VERSION 3.16)
project(moto-buds-gui LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick QuickControls2)
qt_policy(SET QTP0001 NEW)

qt_add_executable(moto-buds-gui
    src/main.cpp
    src/budsbackend.h
    src/budsbackend.cpp
)

qt_add_qml_module(moto-buds-gui
    URI MotoBuds
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/MaterialIcon.qml
        qml/Card.qml
        qml/BatteryCard.qml
        qml/AncSelector.qml
        qml/SettingRow.qml
    RESOURCES
        assets/case_open_buds.webp
        assets/left.webp
        assets/right.webp
        assets/case.webp
        assets/icon.png
        assets/MaterialSymbolsRounded.ttf
)

target_link_libraries(moto-buds-gui PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

include(GNUInstallDirs)
install(TARGETS moto-buds-gui
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
