# Generated Cmake Pico project file

cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Initialise pico_sdk from installed location
# (note this can come from environment, CMake cache etc)

# == DO NOT EDIT THE FOLLOWING LINES for the Raspberry Pi Pico VS Code Extension to work ==
if(WIN32)
    set(USERHOME $ENV{USERPROFILE})
else()
    set(USERHOME $ENV{HOME})
endif()
set(sdkVersion 2.2.0)
set(toolchainVersion 14_2_Rel1)
set(picotoolVersion 2.2.0-a4)
set(picoVscode ${USERHOME}/.pico-sdk/cmake/pico-vscode.cmake)
if (EXISTS ${picoVscode})
    include(${picoVscode})
endif()
# ====================================================================================
set(PICO_BOARD pico2 CACHE STRING "Board type")

# Pull in Raspberry Pi Pico SDK (must be before project)
include(pico_sdk_import.cmake)

project(spi C CXX ASM)

# Initialise the Raspberry Pi Pico SDK
pico_sdk_init()

include(FetchContent)
set(LV_CONF_BUILD_DISABLE_THORVG_INTERNAL ON CACHE BOOL "" FORCE)
set(LV_CONF_BUILD_DISABLE_EXAMPLES ON CACHE BOOL "" FORCE)
set(LV_CONF_BUILD_DISABLE_DEMOS ON CACHE BOOL "" FORCE)
FetchContent_Declare(
        lvgl
        GIT_REPOSITORY https://github.com/lvgl/lvgl.git
        GIT_TAG v9.2.2
        GIT_SHALLOW TRUE
)
FetchContent_MakeAvailable(lvgl)

target_compile_definitions(lvgl PUBLIC LV_CONF_INCLUDE_SIMPLE)
target_include_directories(lvgl PUBLIC ${CMAKE_CURRENT_LIST_DIR})

# Add executable. Default name is the project name, version 0.1

add_executable(spi
        spi.c
        display_spi.c
        synth_ui.c
)

pico_set_program_name(spi "spi")
pico_set_program_version(spi "0.1")

# Modify the below lines to enable/disable output over UART/USB
pico_enable_stdio_uart(spi 0)
pico_enable_stdio_usb(spi 1)

# Add the standard library to the build
target_link_libraries(spi
        pico_stdlib
        hardware_spi
        hardware_gpio
        lvgl)

# Add the standard include files to the build
target_include_directories(spi PRIVATE
        ${CMAKE_CURRENT_LIST_DIR}
)


pico_add_extra_outputs(spi)
