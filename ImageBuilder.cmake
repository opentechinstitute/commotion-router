##################################################################################################
# FILE: ImageBuilder.cmake
# DESCRIPTION: CMake module for downloading and running the OpenWRT ImageBuilder
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
function(imagebuild)
  set(oneValueArgs RELEASE VERSION TARGET SUBTARGET FILES PROFILE DL_DIR REPO_CONF 
    SKIP_MD5 USE_LOCAL DEBUG)
  set(multiValueArgs PACKAGES)
  set(options ) 
  cmake_parse_arguments(IB "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

  #Set list of files to include in image
  if(IS_DIRECTORY ${IB_FILES})
    set(FILES "FILES=${IB_FILES}")
  endif()

  #Set list of packages to include in image
  if(DEFINED IB_PACKAGES)
    set(PACKAGES "PACKAGES=${IB_PACKAGES}")
    #Convert packages list to string
    string(REPLACE ";" " " PACKAGES "${PACKAGES}")
  endif()

  #Set which build profile to use
  if(DEFINED IB_PROFILE)
    set(PROFILE "PROFILE=${IB_PROFILE}")
  endif()

  #Optionally set custom download directory
  if(IS_DIRECTORY ${IB_DL_DIR})
    set(DL_DIR ${IB_DL_DIR})
  else()
    set(DL_DIR ${CMAKE_CURRENT_BINARY_DIR})
  endif()

  #They changed the host architecture for ImageBuilder after 12.09
  if("${IB_VERSION}" VERSION_GREATER 12.09)
    set(FILENAME "OpenWrt-ImageBuilder-${IB_TARGET}_${IB_SUBTARGET}-for-linux-x86_64.tar.bz2") 
  else()
    set(FILENAME "OpenWrt-ImageBuilder-${IB_TARGET}_${IB_SUBTARGET}-for-linux-i486.tar.bz2") 
  endif()

  #Download and grab md5sums
  if(NOT IB_SKIP_MD5)
    if(NOT EXISTS "${DL_DIR}/md5sums")
      message(STATUS "Attempting to download md5sums...")
      file(DOWNLOAD ${OPENWRT_URL}/${IB_RELEASE}/${IB_VERSION}/${IB_TARGET}/${IB_SUBTARGET}/md5sums 
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

  #Don't download ImageBuilder if we've done it already
  if(EXISTS ${DL_DIR}/${FILENAME})
    set(URL "${DL_DIR}/${FILENAME}")
  else()
    set(URL "${OPENWRT_URL}/${IB_RELEASE}/${IB_VERSION}/${IB_TARGET}/${IB_SUBTARGET}/${FILENAME}")
  endif()
  message(STATUS "Grabbing ImageBuilder from ${URL}")

  #If we're using a locally built set of packages, make sure the PackageBuilder runs first.
  if(IB_USE_LOCAL)
    set(DEPENDS "package_builder")
    message(STATUS "ImageBuilder configured to use local packages created by PackageBuilder")
  endif()

  #Set debug verbosity
  if(IB_DEBUG)
    set(VERBOSE "V=s")
    message(STATUS "Setting ImageBuilder to use verbose output")
  endif()

  #Actually download, extract, and run ImageBuilder
  include(ExternalProject)
  if(EXISTS ${IB_REPO_CONF})
    ExternalProject_Add(image_builder
      DEPENDS "${DEPENDS}"
      URL ${URL}
      URL_MD5 ${MD5SUM}
      PREFIX "${CMAKE_CURRENT_BINARY_DIR}"
      DOWNLOAD_DIR "${DL_DIR}"
      INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/"
      PATCH_COMMAND ""
      UPDATE_COMMAND ""
      CONFIGURE_COMMAND cp "${IB_REPO_CONF}" 
        "${CMAKE_CURRENT_BINARY_DIR}/src/image_builder/repositories.conf"
      BUILD_IN_SOURCE 1
      BUILD_COMMAND make image ${PROFILE} ${FILES} ${PACKAGES} ${VERBOSE} 
      INSTALL_COMMAND "find" ${CMAKE_CURRENT_BINARY_DIR}/src/image_builder/bin/${TARGET} -type f 
        -exec mv -f --target-directory ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/  
        {} \$<SEMICOLON>
        COMMAND tar -cf ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/image_builder.tar 
          -C .. image_builder/
        COMMAND ln -s ${IB_FILES} ./files
        COMMAND "find" ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET} -type f
          -name *.ipk -exec ln -s {} ./dl \$<SEMICOLON>
        COMMAND tar -rhf ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/image_builder.tar 
          -C .. image_builder/files
        COMMAND tar -rhf ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/image_builder.tar 
          -C .. image_builder/dl
        COMMAND bzip2 ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/image_builder.tar 
    )
  else()
    ExternalProject_Add(image_builder
      DEPENDS "${DEPENDS}"
      URL ${URL}
      URL_MD5 ${MD5SUM}
      PREFIX "${CMAKE_CURRENT_BINARY_DIR}"
      DOWNLOAD_DIR "${DL_DIR}"
      INSTALL_DIR "${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/"
      PATCH_COMMAND ""
      UPDATE_COMMAND ""
      CONFIGURE_COMMAND ""
      BUILD_IN_SOURCE 1
      BUILD_COMMAND make image ${PROFILE} ${FILES} ${PACKAGES} ${VERBOSE}
      INSTALL_COMMAND "find" ${CMAKE_CURRENT_BINARY_DIR}/src/image_builder/bin/${TARGET} -type f 
        -exec mv -f --target-directory ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/  
        {} \$<SEMICOLON>
        COMMAND tar -cf ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/image_builder.tar 
          -C .. image_builder/
        COMMAND ln -s ${IB_FILES} ./files
        COMMAND "find" ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET} -type f
          -name *.ipk -exec ln -s {} ./dl \$<SEMICOLON>
        COMMAND tar -rhf ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/image_builder.tar 
          -C .. image_builder/files
        COMMAND tar -rhf ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/image_builder.tar 
          -C .. image_builder/dl
        COMMAND bzip2 ${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}/image_builder.tar 
    )
  endif()
endfunction()  
