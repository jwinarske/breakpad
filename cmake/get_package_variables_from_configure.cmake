
FILE (READ "${top_srcdir}/configure" file_content)

SET(search_pkg           "^.*PACKAGE='([A-Za-z]+)'.*$")
SET(search_pkg_name      "^.*PACKAGE_NAME='([A-Za-z]+)'.*$")
SET(search_pkg_tarname   "^.*PACKAGE_TARNAME='([A-Za-z]+)'.*$")
SET(search_pkg_version   "^.*PACKAGE_VERSION='([0-9.]+)'.*$")
SET(search_pkg_string    "^.*PACKAGE_STRING='([A-Za-z0-9. ]+)'.*$")
SET(search_pkg_bugreport "^.*PACKAGE_BUGREPORT='([a-z0-9:/@.-]+)'.*$")
SET(search_pkg_url       "^.*PACKAGE_URL='([A-Za-z0-9.:/ ]+)'.*$")


STRING(REGEX MATCH ${search_pkg} _ ${file_content})
SET(PACKAGE ${CMAKE_MATCH_1})

STRING(REGEX MATCH ${search_pkg_name} _ ${file_content})
SET(PACKAGE_NAME ${CMAKE_MATCH_1})

STRING(REGEX MATCH ${search_pkg_tarname} _ ${file_content})
SET(PACKAGE_TARNAME ${CMAKE_MATCH_1})

STRING(REGEX MATCH ${search_pkg_version} _ ${file_content})
SET(PACKAGE_VERSION ${CMAKE_MATCH_1})

STRING(REGEX MATCH ${search_pkg_string} _ ${file_content})
SET(PACKAGE_STRING ${CMAKE_MATCH_1})

STRING(REGEX MATCH ${search_pkg_bugreport} _ ${file_content})
SET(PACKAGE_BUGREPORT ${CMAKE_MATCH_1})

STRING(REGEX MATCH ${search_pkg_url} _ ${file_content})
SET(PACKAGE_URL ${CMAKE_MATCH_1})

MESSAGE(STATUS "PACKAGE=${PACKAGE}")
MESSAGE(STATUS "PACKAGE_NAME=${PACKAGE_NAME}")
MESSAGE(STATUS "PACKAGE_TARNAME=${PACKAGE_TARNAME}")
MESSAGE(STATUS "PACKAGE_VERSION=${PACKAGE_VERSION}")
MESSAGE(STATUS "PACKAGE_STRING=${PACKAGE_STRING}")
MESSAGE(STATUS "PACKAGE_BUGREPORT=${PACKAGE_BUGREPORT}")
MESSAGE(STATUS "PACKAGE_URL=${PACKAGE_URL}")

