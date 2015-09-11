##################################################################################################
# FILE: PackageBuilder.cmake
# DESCRIPTION: CMake module for downloading and running the OpenWRT SDK
# 
# Copyright (c) 2014, Josh King
#
# This file is part of Commotion-Router.
# 
# Commotion-Router is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Commotion-Router is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Commotion-Router.  If not, see <http://www.gnu.org/licenses/>.
##################################################################################################

cmake_minimum_required(VERSION 2.8)

include(CMakeParseArguments)

#Set download URL
set(OPENWRT_URL "http://downloads.openwrt.org/") 

#Main function for downloading and running the OpenWRT Imagebuilder
function(packagebuild)
  set(oneValueArgs RELEASE VERSION TARGET SUBTARGET FEEDS_CONF DL_DIR JOBS SKIP_MD5 DEBUG)
  set(multiValueArgs PACKAGES BUILD_TARGETS)
  set(options )
  cmake_parse_arguments(PB "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  #Check list of packages to install into buildsystem
  if(NOT DEFINED PB_PACKAGES)
    message(FATAL_ERROR "No packages defined.")
  endif()
  
  #Set list of package build targets
  if(DEFINED PB_BUILD_TARGETS)
    #Convert packages list to comma-delimited string
    list(LENGTH PB_BUILD_TARGETS LEN)
    if(LEN GREATER 1)
      foreach(loop_var IN LISTS PB_BUILD_TARGETS)
        list(APPEND BUILD_TARGETS "package/${loop_var}/compile")
      endforeach()
    else()
      set(BUILD_TARGETS "package/${PB_BUILD_TARGETS}/compile")
    endif()
  else()
    message(FATAL_ERROR "No build targets defined.")
  endif()

  #Optionally set custom download directory
  if(IS_DIRECTORY ${PB_DL_DIR})
    set(DL_DIR ${PB_DL_DIR})
  else()
    set(DL_DIR ${CMAKE_CURRENT_BINARY_DIR})
  endif()

  #They changed the host architecture for the SDK after 12.09
  set(FILENAME "OpenWrt-SDK-${PB_TARGET}-for-linux-x86_64-gcc-4.8-linaro_uClibc-0.9.33.2.tar.bz2") 

  #Download and grab md5sums
  if(NOT PB_SKIP_MD5)
    if(NOT EXISTS "${DL_DIR}/md5sums")
      message(STATUS "Attempting to download md5sums...")
      file(DOWNLOAD 
        "${OPENWRT_URL}/${PB_RELEASE}/${PB_VERSION}/${PB_TARGET}/${PB_SUBTARGET}/md5sums"
        "${DL_DIR}/md5sums" INACTIVITY_TIMEOUT 10)
      message(STATUS "md5sum path: ${DL_DIR}/md5sums")
    endif()
    message(STATUS "Extracting md5sum for ${FILENAME}...")
    execute_process(
      COMMAND grep ${FILENAME} "${DL_DIR}/md5sums"
      COMMAND cut -d " " -f1
      OUTPUT_STRIP_TRAILING_WHITESPACE
      OUTPUT_VARIABLE MD5SUM
    )
    if(NOT DEFINED MD5SUM)
      message(WARNING "Error: md5sum not defined.")
    endif()
  endif()
  message(STATUS "MD5SUM: ${MD5SUM}")

  #Don't download the SDK if we've done it already
  if(EXISTS "${DL_DIR}/${FILENAME}")
    set(URL "${DL_DIR}/${FILENAME}")
  else()
    set(URL "${OPENWRT_URL}/${PB_RELEASE}/${PB_VERSION}/${PB_TARGET}/${PB_SUBTARGET}/${FILENAME}")
  endif()
  message(STATUS "Grabbing PackageBuilder from ${URL}")

  #Set number of compile jobs
  if(DEFINED PB_JOBS)
    set(JOBS "-j${PB_JOBS}")
    message(STATUS "Setting number of simultaneous PackageBuilder jobs to ${PB_JOBS}")
  endif()

  #Set debug verbosity
  if(PB_DEBUG)
    set(VERBOSE "V=s")
    message(STATUS "Setting PackageBuilder to use verbose output")
  endif()

  #Actually download, extract, and run the SDK
  include(ExternalProject)
  if(EXISTS ${PB_FEEDS_CONF})
    ExternalProject_Add(package_builder
      URL ${URL}
      URL_MD5 ${MD5SUM}
      PREFIX "${CMAKE_CURRENT_BINARY_DIR}"
      DOWNLOAD_DIR "${DL_DIR}"
      INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/packages/"
      PATCH_COMMAND cp "${PB_FEEDS_CONF}" 
        "${CMAKE_CURRENT_BINARY_DIR}/src/package_builder/feeds.conf"
      UPDATE_COMMAND LC_ALL=C ./scripts/feeds update -a
      CONFIGURE_COMMAND ./scripts/feeds uninstall ${PB_PACKAGES}
        COMMAND ./scripts/feeds install -p commotion ${PB_PACKAGES}
        COMMAND ${PROJECT_SOURCE_DIR}/clean-feed.sh ./feeds/commotion/packages 
      BUILD_IN_SOURCE 1
      BUILD_COMMAND make ${BUILD_TARGETS} ${JOBS} ${VERBOSE} 
      INSTALL_COMMAND cp -rf ${CMAKE_CURRENT_BINARY_DIR}/src/package_builder/bin/${TARGET}/packages 
        ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/
        COMMAND ${PROJECT_SOURCE_DIR}/ipkg-multi-index.sh  
          ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/packages
    )
  else()
    ExternalProject_Add(package_builder
      URL ${URL}
      URL_MD5 ${MD5SUM}
      PREFIX "${CMAKE_CURRENT_BINARY_DIR}"
      DOWNLOAD_DIR "${DL_DIR}"
      INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/packages/"
      PATCH_COMMAND ""
      UPDATE_COMMAND LC_ALL=C ./scripts/feeds update -a
      CONFIGURE_COMMAND ./scripts/feeds uninstall ${PB_PACKAGES}
        COMMAND ./scripts/feeds install -p commotion ${PB_PACKAGES}
        COMMAND ${PROJECT_SOURCE_DIR}/clean-feed.sh ./feeds/commotion/packages 
      BUILD_IN_SOURCE 1
      BUILD_COMMAND make ${BUILD_TARGETS} ${JOBS} ${VERBOSE} 
      INSTALL_COMMAND cp -rf ${CMAKE_CURRENT_BINARY_DIR}/src/package_builder/bin/${TARGET}/packages 
        ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/
        COMMAND ${PROJECT_SOURCE_DIR}/ipkg-multi-index.sh  
          ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/packages
    )
  endif()
endfunction()  
