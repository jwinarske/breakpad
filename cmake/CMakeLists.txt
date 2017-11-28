cmake_minimum_required(VERSION 3.3 FATAL_ERROR)
CMAKE_POLICY(SET CMP0048 NEW)

set(top_srcdir ${CMAKE_SOURCE_DIR}/..)
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} ${top_srcdir}/cmake)

include(get_package_variables_from_configure)

PROJECT(${PACKAGE_NAME} VERSION "${PACKAGE_VERSION}" LANGUAGES C CXX)

set (CMAKE_CXX_STANDARD 11)

set(GTEST_VERSION 1.8.0)

OPTION(DISABLE_HOST "Don't build host tools" OFF)
OPTION(ENABLE_M32 "Compile/build with -m32" OFF)
OPTION(DISABLE_LARGEFILE "omit support for large files" OFF)
OPTION(DISABLE_PROCESSOR "Don't build processor library" OFF)
OPTION(DISABLE_TOOLS "Don't build tool binaries" OFF)
OPTION(ENABLE_SYSTEM_TEST_LIBS "Use gtest/gmock/etc... from the system instead of
the local copies" OFF)
OPTION(ENABLE_SELFTEST "Run extra tests with 'make check' (may conflict with
optimizations)" OFF)


include(gen_config_header)
include(create_pkg_files)
include(set_cxx_warning_flags)

set(includedir ${CMAKE_INSTALL_PREFIX}/install)

IF(NOT DISABLE_HOST)
  IF(UNIX)
    IF(APPLE)
    ELSEIF(ANDROID)
      # This allows using fixed NDK headers when building for Android.
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I${top_srcdir}/src/common/android/include")
      # This is only necessary for building the unit tests until GTest is upgraded
      # to a future version.
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -I${top_srcdir}/src/common/android/testing/include")
    ELSEIF(CYGWIN)
    ELSE()
      # Build as PIC on Linux, for linux_client_unittest_shlib
      set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -fPIC")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fPIC")
    ENDIF()
  ENDIF()

  set(includeclhdir ${includedir}/${PACKAGE}/client/linux/handler)
  set(includeclh_HEADERS ${top_srcdir}/src/client/linux/handler/*.h)

  set(includecldwcdir ${includedir}/${PACKAGE}/client/linux/dump_writer_common)
  set(includecldwc_HEADERS ${top_srcdir}/src/client/linux/dump_writer_common/*.h)

  set(includeclmdir ${includedir}/${PACKAGE}/client/linux/minidump_writer)
  set(includeclm_HEADERS ${top_srcdir}/src/client/linux/minidump_writer/*.h)

  set(includeclcdir ${includedir}/${PACKAGE}/client/linux/crash_generation)
  set(includeclc_HEADERS ${top_srcdir}/src/client/linux/crash_generation/*.h)

  set(includelssdir ${includedir}/${PACKAGE}/third_party/lss)
  set(includelss_HEADERS ${top_srcdir}/src/third_party/lss/*.h)

  set(includecldir ${includedir}/${PACKAGE}/common/linux)
  set(includecl_HEADERS ${top_srcdir}/src/common/linux/*.h)

  ENDIF()

set(includegbcdir ${includedir}/${PACKAGE}/google_breakpad/common)
set(includegbc_HEADERS ${top_srcdir}/src/google_breakpad/common/*.h)

set(includecdir ${includedir}/${PACKAGE}/common)
set(includec_HEADERS ${top_srcdir}/src/common/*.h)

set(includepdir ${includedir}/${PACKAGE}/processor)
set(includep_HEADERS ${top_srcdir}/src/processor/*.h)

# Documentation
set(docdir ${prefix}/share/doc/${PACKAGE}-${VERSION})

enable_testing()
IF (NOT ENABLE_SYSTEM_TEST_LIBS)
  include (google_test_external)
ELSE()
  FIND_PACKAGE(PkgConfig)
  IF (PKG_CONFIG_FOUND)
    PKG_CHECK_MODULES(GTEST googletest)
    IF (GTEST_FOUND)
      MESSAGE(STATUS "System GoogleTest found!")
    ELSE ()
      MESSAGE(STATUS "System GoogleTest not found!")
    ENDIF ()
  ENDIF ()
ENDIF()

ADD_CUSTOM_TARGET(uninstall "${CMAKE_COMMAND}" -P "${CMAKE_SOURCE_DIR}/cmake/make_uninstall.cmake")
