#-------------------------------------------------------------------------------
#   android.toolchain.cmake
#
#   NOTE: this script expects a standalone android toolchain built
#   with [ndk-dir]/build/tools/make-standalone-toolchain.sh with the 
#   directory name 'android-toolchain':
#   sh make-standalone-toolchain.sh –-platform=android-19 
#                                   –-ndk-dir=/Users/[user]/android-ndk-r9d 
#                                   –-install-dir=/Users/[user]/android-toolchain 
#                                   –-toolchain=arm-linux-androideabi-4.8
#                                   --system=darwin-x86_64
#-------------------------------------------------------------------------------

# set the name of the custom android-toolchain
set(ANDROID_TOOLCHAIN_DIRNAME "android-toolchain" CACHE STRING "Standalone Android toolchain directory name")
set(ANDROID_PLATFORM "android-19" CACHE STRING "Android platform version")
set(ANDROID_NDK_ABI "arm-linux-androideabi" CACHE STRING "Android ABI name")
set(ANDROID_NDK_CPU "armeabi-v7a" CACHE STRING "Android CPU instruction set identifier")
if (${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    # FIXME: is this the right directory name?
    set(ANDROID_SDK_DIRNAME "android-sdk-windows")
elseif (${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
    set(ANDROID_SDK_DIRNAME "android-sdk-macosx")
elseif (${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
    # FIXME: is this the right directory name?
    set(ANDROID_SDK_DIRNAME "android-sdk-linux")
endif()

set(ORYOL_PLATFORM ANDROID)
set(ORYOL_PLATFORM_NAME "android")
set(ORYOL_ANDROID 1)
set(ORYOL_POSIX 1)
set(ORYOL_OPENGL 1)
set(ORYOL_OPENGLES2 1)
set(ORYOL_PLATFORM_DEFINES "-DORYOL_ANDROID=1 -DORYOL_POSIX=1")

# verbose compile mode? (to check how headers and link libs are resolved)
if (ORYOL_COMPILE_VERBOSE)
    set(ORYOL_ANDROID_COMPILE_VERBOSE "-v")
    set(ORYOL_ANDROID_LINK_VERBOSE "-Wl,--verbose")
else()
    set(ORYOL_ANDROID_COMPILE_VERBOSE "")
    set(ORYOL_ANDROID_LINK_VERBOSE "")
endif()

# exceptions on/off?
if (ORYOL_EXCEPTIONS)
    message("C++ exceptions are enabled")
    set(ORYOL_ANDROID_EXCEPTION_FLAGS "")
else()
    message("C++ exceptions are disabled")
    set(ORYOL_ANDROID_EXCEPTION_FLAGS "-fno-exceptions")
endif()

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_VERSION 1)
set(COMPILING on)
set(CMAKE_CROSSCOMPILING TRUE)

macro(find_relative_dir outPath relPath fileToTest)
    if ("${${outPath}}" STREQUAL "")
        get_filename_component(CHECK_PATH "${CMAKE_CURRENT_LIST_DIR}/${relPath}" ABSOLUTE)
        message("Checking ${CHECK_PATH}/")
        if (EXISTS "${CHECK_PATH}/${fileToTest}")
            set(${outPath} "${CHECK_PATH}")
        endif()
    endif()
endmacro()

macro(find_android_toolchain_root)

    # first try environment variable
    if ("${ANDROID_TOOLCHAIN_ROOT}" STREQUAL "")
        message("Checking env variable ANDROID_TOOLCHAIN_ROOT...")
        set(ANDROID_TOOLCHAIN_ROOT "$ENV{ANDROID_TOOLCHAIN_ROOT}")
    endif()

    # then try relative paths
    find_relative_dir(ANDROID_TOOLCHAIN_ROOT "../${ANDROID_TOOLCHAIN_DIRNAME}" "SOURCES")
    find_relative_dir(ANDROID_TOOLCHAIN_ROOT "../../${ANDROID_TOOLCHAIN_DIRNAME}" "SOURCES")
    find_relative_dir(ANDROID_TOOLCHAIN_ROOT "../../../${ANDROID_TOOLCHAIN_DIRNAME}" "SOURCES")
    find_relative_dir(ANDROID_TOOLCHAIN_ROOT "../../../../${ANDROID_TOOLCHAIN_DIRNAME}" "SOURCES")
    if ("${ANDROID_TOOLCHAIN_ROOT}" STREQUAL "")
        message(FATAL_ERROR "Could not locate Android standalone toolchain (${ANDROID_TOOLCHAIN_DIRNAME})! Either set the ANDROID_TOOLCHAIN_ROOT environment variable, or pass -DANDROID_TOOLCHAIN_ROOT=xxx to cmake to explicitly specify the path!")
    else()
        message("Android standalone toolchain found: ${ANDROID_TOOLCHAIN_ROOT}")
        set(ANDROID_TOOLCHAIN_ROOT ${ANDROID_TOOLCHAIN_ROOT} CACHE STRING "Android standalone toolchain path")
    endif()
endmacro()

macro(find_android_sdk_root)

    # first try environment variable
    if ("${ANDROID_SDK_ROOT}" STREQUAL "")
        message("Checking env variable ANDROID_SDK_ROOT...")
        set(ANDROID_SDK_ROOT "$ENV{ANDROID_SDK_ROOT}")
    endif()

    # then try relative paths
    find_relative_dir(ANDROID_SDK_ROOT "../${ANDROID_SDK_DIRNAME}" "tools/android")
    find_relative_dir(ANDROID_SDK_ROOT "../../${ANDROID_SDK_DIRNAME}" "tools/android")
    find_relative_dir(ANDROID_SDK_ROOT "../../../${ANDROID_SDK_DIRNAME}" "tools/android")
    find_relative_dir(ANDROID_SDK_ROOT "../../../../${ANDROID_SDK_DIRNAME}" "tools/android")
    if ("${ANDROID_SDK_ROOT}" STREQUAL "")
        message(FATAL_ERROR "Could not locate Android SDK (${ANDROID_SDK_DIRNAME})! Either set the ANDROID_SDK_ROOT environment variable, or pass -DANDROID_SDK_ROOT=xxx to cmake to explicitely specify the path!")
    else()
        message("Android SDK found: ${ANDROID_SDK_ROOT}")
        set(ANDROID_SDK_ROOT ${ANDROID_SDK_ROOT} CACHE STRING "Android SDK location.")
    endif()
endmacro()

# try to find the Android standalone toolchain and the Android SDK
find_android_toolchain_root()
find_android_sdk_root()

# set path to Android tool
set(ANDROID_SDK_TOOL "${ANDROID_SDK_ROOT}/tools/android")

# find the ant tool
find_program(ANDROID_ANT "ant")
if (ANDROID_ANT)
    message("ant tool found")
else()
    message(FATAL_ERROR "ant tool NOT FOUND (must be in path)!")
endif()

# set path to toolchain binaries
set(ANDROID_SYSROOT "${ANDROID_TOOLCHAIN_ROOT}/sysroot")
set(ANDROID_TOOLCHAIN_BIN "${ANDROID_TOOLCHAIN_ROOT}/bin")
set(ANDROID_TOOLCHAIN_INCLUDE "${ANDROID_TOOLCHAIN_ROOT}/include")
set(ANDROID_TOOLCHAIN_LIB "${ANDROID_TOOLCHAIN_ROOT}/lib")
set(ANDROID_SYSROOT_INCLUDE "${ANDROID_SYSROOT}/usr/include")
set(ANDROID_SYSROOT_LIB "${ANDROID_SYSROOT}/usr/lib")

message("ANDROID_SYSROOT: ${ANDROID_SYSROOT}")
message("ANDROID_TOOLCHAIN_BIN: ${ANDROID_TOOLCHAIN_BIN}")
message("ANDROID_TOOLCHAIN_INCLUDE: ${ANDROID_TOOLCHAIN_INCLUDE}")
message("ANDROID_TOOLCHAIN_LIB: ${ANDROID_TOOLCHAIN_LIB}")
message("ANDROID_SYSROOT_INCLUDE: ${ANDROID_SYSROOT_INCLUDE}")
message("ANDROID_SYSROOT_LIB: ${ANDROID_SYSROOT_LIB}")

# standard header and lib search paths
include_directories(${ANDROID_TOOLCHAIN_INCLUDE} ${ANDROID_SYSROOT_INCLUDE})
link_directories(${ANDROID_TOOLCHAIN_LIB})

# disable compiler detection
include(CMakeForceCompiler)
CMAKE_FORCE_C_COMPILER("${CMAKE_C_COMPILER}" GNU)
CMAKE_FORCE_CXX_COMPILER("${CMAKE_CXX_COMPILER}" GNU)

# define configurations
set(CMAKE_CONFIGURATION_TYPES Debug Release)

# specify cross-compilers
set(CMAKE_C_COMPILER "${ANDROID_TOOLCHAIN_BIN}/${ANDROID_NDK_ABI}-gcc" CACHE PATH "gcc" FORCE)
set(CMAKE_CXX_COMPILER "${ANDROID_TOOLCHAIN_BIN}/${ANDROID_NDK_ABI}-g++" CACHE PATH "g++" FORCE)
set(CMAKE_AR "${ANDROID_TOOLCHAIN_BIN}/${ANDROID_NDK_ABI}-ar" CACHE PATH "archive" FORCE)
set(CMAKE_LINKER "${ANDROID_TOOLCHAIN_BIN}/${ANDROID_NDK_ABI}-g++" CACHE PATH "linker" FORCE)
set(CMAKE_RANLIB "${ANDROID_TOOLCHAIN_BIN}/${ANDROID_NDK_ABI}-ranlib" CACHE PATH "ranlib" FORCE)

# only search for libraries and includes in the toolchain
set(CMAKE_FIND_ROOT_PATH ${ANDROID_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_SYSTEM_INCLUDE_PATH "${ANDROID_SYSROOT_INCLUDE}")

set(ANDROID_CXX_FLAGS "${ORYOL_ANDROID_COMPILE_VERBOSE} -fpic -ffunction-sections -funwind-tables -fstack-protector -no-canonical-prefixes -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=softfp -mthumb -mhard-float -DANDROID -mhard-float -D_NDK_MATH_NO_SOFTFP=1 -Wa,--noexecstack -Wformat -Werror=format-security")
set(ANDROID_LD_FLAGS "-shared -no-canonical-prefixes -march=armv7-a -Wl,--fix-cortex-a8 -Wl,--no-warn-mismatch -Wl,--no-warn-mismatch -Wl,--no-undefined -Wl,-z,noexecstack -Wl,-z,relro -Wl,-z,now ${ANDROID_LINK_VERBOSE}")

# c++ compiler flags
set(CMAKE_CXX_FLAGS "${ANDROID_CXX_FLAGS} ${ORYOL_PLATFORM_DEFINES} -std=gnu++11 ${ORYOL_ANDROID_EXCEPTION_FLAGS} -Wall -Wno-multichar -Wextra -Wno-unused-parameter -Wno-unknown-pragmas -Wno-ignored-qualifiers -Wno-long-long -Wno-overloaded-virtual")
set(CMAKE_CXX_FLAGS_RELEASE "-Os -fomit-frame-pointer -fstrict-aliasing -funswitch-loops -finline-limit=300 -DNDEBUG")
set(CMAKE_CXX_FLAGS_DEBUG "-O0 -fno-omit-frame-pointer -fno-strict-aliasing -g -D_DEBUG_ -D_DEBUG -DORYOL_DEBUG=1")
message("CMAKE_CXX_FLAGS: ${CMAKE_CXX_FLAGS}")

# c compiler flags
set(CMAKE_C_FLAGS "${ANDROID_CXX_FLAGS} ${ORYOL_PLATFORM_DEFINES} -Wall -Wno-multichar -Wextra -Wno-unused-parameter -Wno-unknown-pragmas -Wno-ignored-qualifiers -Wno-long-long")
set(CMAKE_C_FLAGS_RELEASE "-O2 -fomit-frame-pointer -fstrict-aliasing -funswitch-loops -finline-limit=300 -DNDEBUG")
set(CMAKE_C_FLAGS_DEBUG "-O0 -fno-omit-frame-pointer -fno-strict-aliasing -g -D_DEBUG_ -D_DEBUG -DORYOL_DEBUG=1")
message("CMAKE_C_FLAGS: ${CMAKE_C_FLAGS}")

# shared linker flags (native code on Android always lives in DLLs)
set(CMAKE_SHARED_LINKER_FLAGS "${ANDROID_LD_FLAGS} -pthread -dead_strip")
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "")
set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "")

# update cache variables for cmake gui
set(CMAKE_CONFIGURATION_TYPES "${CMAKE_CONFIGURATION_TYPES}" CACHE STRING "Config Type" FORCE)
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS}" CACHE STRING "Generic C++ Compiler Flags" FORCE)
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG}" CACHE STRING "C++ Debug Compiler Flags" FORCE)
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}" CACHE STRING "C++ Release Compiler Flags" FORCE)
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS}" CACHE STRING "Generic C Compiler Flags" FORCE)
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG}" CACHE STRING "C Debug Compiler Flags" FORCE)
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}" CACHE STRING "C Release Compiler Flags" FORCE)
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS}" CACHE STRING "Generic Linker Flags" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_DEBUG "${CMAKE_EXE_LINKER_FLAGS_DEBUG}" CACHE STRING "Debug Linker Flags" FORCE)
set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE}" CACHE STRING "Release Linker Flags" FORCE)
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS}" CACHE STRING "Generic Shared Linker Flags" FORCE)
set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "${CMAKE_SHARED_LINKER_FLAGS_DEBUG}" CACHE STRING "Debug Shared Linker Flags" FORCE)
set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE}" CACHE STRING "Release Shared Linker Flags" FORCE)

# set the build type to use
if (NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE "Debug" CACHE STRING "Compile Type" FORCE)
endif()
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS Debug Release)
