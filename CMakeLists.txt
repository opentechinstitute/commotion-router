##################################################################################################
# FILE: CMakelists.txt
# DESCRIPTION: The main CMake file for building Commotion Router images.
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

##################################################################################################
# PROJECT
##################################################################################################
cmake_minimum_required(VERSION 3.0.2)

include(ImageBuilder.cmake)
include(PackageBuilder.cmake)

#Hide unnecessary cache variables for cmake-gui
mark_as_advanced(CMAKE_C_COMPILER)
mark_as_advanced(CMAKE_CXX_COMPILER)
mark_as_advanced(CMAKE_INSTALL_PREFIX)

#Set up project
project(commotion-router VERSION 1.1.0 LANGUAGES NONE)

##################################################################################################
# GLOBALS
##################################################################################################
#Set up variables for cache configuration
set(DEBUG OFF CACHE BOOL "Create verbose Makefile output")
set(COMMOTION_VERSION "master" CACHE STRING "Branch of Commotion to build")
set(COMMOTION_RELEASE "grumpy_cat" CACHE STRING "Commotion release nickname")
set(SKIP_MD5 OFF CACHE BOOL "Skip MD5 checking of downloaded ImageBuilder & PackageBuilder files")
set(COMMOTION_PACKAGES "commotion;commotion-gui;nodewatcher-agent;nodeupgrade;identity-pubkey" CACHE INTERNAL "Commotion default packages")
set(PACKAGEBUILD_TARGETS "commotion;nodewatcher-agent;nodeupgrade;identity-pubkey" CACHE INTERNAL "Make targets for PackageBuilder")
set(OPENWRT_VERSION "14.07" CACHE INTERNAL "OpenWRT version number")
set(OPENWRT_RELEASE "barrier_breaker" CACHE INTERNAL "OpenWRT release nickname")
set(BUILD_IMAGES ON CACHE BOOL "Toggle building of images")
set(BUILD_PACKAGES OFF CACHE BOOL "Toggle building of packages")
set(USE_LOCAL OFF CACHE BOOL "Use the locally built packages when building images")
set(JOBS "2" CACHE STRING "Number of parallel compile jobs") 
set(DL_DIR ${CMAKE_CURRENT_BINARY_DIR} CACHE FILEPATH "Custom download directory") 

#Verbose Makefile
if(DEBUG)
  set(CMAKE_VERBOSE_MAKEFILE ON)
endif()

#Router default files
set(CONFIGS_DIR "${PROJECT_SOURCE_DIR}/configs")
set(FILES_DIR "${PROJECT_SOURCE_DIR}/files")
set(UPGRADES_DIR "${PROJECT_SOURCE_DIR}/upgrades")

##################################################################################################
# MACROS
##################################################################################################
#Macro for listing config subdirectories.
macro(config_list CONFIG_LIST CONFIGS_DIR)
  file(GLOB CHILDREN RELATIVE ${CONFIGS_DIR} ${CONFIGS_DIR}/*)
  set(DIR_LIST "")
  foreach(CHILD ${CHILDREN})
    if(IS_DIRECTORY ${CONFIGS_DIR}/${CHILD})
      list(APPEND DIR_LIST ${CHILD})
    endif()
  endforeach()
  set(${CONFIG_LIST} ${DIR_LIST})
endmacro()

#Assert macro
macro(defined VARIABLE ERR_MESSAGE)
  if(NOT DEFINED ${VARIABLE})
    message(FATAL_ERROR ${ERR_MESSAGE})
  endif()
endmacro()

#Macro for choosing which router configuration to use
macro(choose_config CONFIG_PATH)
  if(NOT IS_DIRECTORY ${CONFIG_PATH})
    message(FATAL_ERROR "Error: Configuration doesn't exist!")
  endif()
  add_subdirectory(${CONFIG_PATH})
  defined(TARGET "Error: Target not defined in configuration!")
  defined(SUBTARGET "Error: Subtarget not defined in configuration!")
  defined(PROFILE "Error: Profile not defined in configuration!")
endmacro()

##################################################################################################
# SETUP
##################################################################################################

#Get list of available router configs and select one in cache
config_list(CONFIG_LIST ${CONFIGS_DIR})
set(CONFIG "ubnt" CACHE STRING "Commotion Router configuration")
set_property(CACHE CONFIG PROPERTY STRINGS "${CONFIG_LIST}")
choose_config("${CONFIGS_DIR}/${CONFIG}")

#Create list of all packages to include in images
if(DEFINED PACKAGES)
  list(APPEND ALL_PACKAGES ${COMMOTION_PACKAGES} ${PACKAGES})
else()
  set(ALL_PACKAGES ${COMMOTION_PACKAGES})
endif()
  
##################################################################################################
# BUILD
##################################################################################################
if(NOT BUILD_PACKAGES AND NOT BUILD_IMAGES)
  message(FATAL_ERROR "Not building images or packages, nothing to do!")
endif()

#Call Packagebuilder
if(BUILD_PACKAGES)
  #Add Commotion package feed to feeds.conf
  set(FEEDS_CONF "${CMAKE_CURRENT_BINARY_DIR}/feeds.conf")
  configure_file("${PROJECT_SOURCE_DIR}/feeds.conf.in" "${FEEDS_CONF}")

  packagebuild(RELEASE "${OPENWRT_RELEASE}" VERSION "${OPENWRT_VERSION}" TARGET "${TARGET}" 
    SUBTARGET "${SUBTARGET}" FEEDS_CONF "${FEEDS_CONF}" PACKAGES "${ALL_PACKAGES}" BUILD_TARGETS 
    ${PACKAGEBUILD_TARGETS} JOBS ${JOBS} DEBUG ${DEBUG} DL_DIR ${DL_DIR} SKIP_MD5 ${SKIP_MD5})
endif()

#Call Imagebuilder
if(BUILD_IMAGES)
  #Remove existing files directory
  if(IS_DIRECTORY ${FILES_DIR})
    file(REMOVE_RECURSE ${CMAKE_CURRENT_BINARY_DIR}/files)
  endif()

  #Copy default configuration files
  if(IS_DIRECTORY ${FILES_DIR})
    file(COPY ${FILES_DIR}/ DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
  endif()

  #Copy config-specific configuration files
  if(IS_DIRECTORY ${CONFIGS_DIR}/${CONFIG}/files)
    file(COPY ${CONFIGS_DIR}/${CONFIG}/files/ DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
  endif()

  #Write version identification files
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/files/etc/openwrt_version "${COMMOTION_VERSION}")
  file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/files/etc/openwrt_release "${COMMOTION_RELEASE}")

  #Write banner
  configure_file("${PROJECT_SOURCE_DIR}/banner.in" 
    ${CMAKE_CURRENT_BINARY_DIR}/files/etc/banner)
  
  #Write opkg.conf
  configure_file("${PROJECT_SOURCE_DIR}/opkg.conf.in" 
    ${CMAKE_CURRENT_BINARY_DIR}/files/etc/opkg.conf)
  
  #Set repository configuration location
  set(REPO_CONF "${CMAKE_CURRENT_BINARY_DIR}/repositories.conf")

  #Add Commotion package repository to repositories.conf
  set(LOCAL OFF)
  if(USE_LOCAL)
    if(BUILD_PACKAGES)
      set(LOCAL ON)
      configure_file("${PROJECT_SOURCE_DIR}/repositories.conf.local.in" "${REPO_CONF}")
    else()
      message(WARNING "BUILD_PACKAGES not set, using remote repository.")
      configure_file("${PROJECT_SOURCE_DIR}/repositories.conf.remote.in" "${REPO_CONF}")
    endif()
  else()
    configure_file("${PROJECT_SOURCE_DIR}/repositories.conf.remote.in" "${REPO_CONF}")
  endif()

  imagebuild(RELEASE "${OPENWRT_RELEASE}" VERSION "${OPENWRT_VERSION}" TARGET "${TARGET}" 
    SUBTARGET "${SUBTARGET}" FILES "${CMAKE_CURRENT_BINARY_DIR}/files" 
    PACKAGES "${ALL_PACKAGES}" PROFILE "${PROFILE}" SKIP_MD5 ${SKIP_MD5} 
    REPO_CONF "${REPO_CONF}" USE_LOCAL ${LOCAL} DEBUG ${DEBUG} DL_DIR ${DL_DIR})
endif()

##################################################################################################
# CREATE UPGRADE BUNDLES
##################################################################################################
if(IS_DIRECTORY ${UPGRADES_DIR} AND EXISTS ${UPGRADES_DIR}/manifest)
  set(MAKE_BUNDLES ON CACHE BOOL "Turn built images into Commotion upgrade bundles")
  set(SIGN_UPGRADE OFF CACHE BOOL "Sign upgrade manifest with a Serval signing key")
  set(KEYRING "" CACHE FILEPATH "Serval keyring for signing upgrade manifest (optional)")
  set(PUBLIC_KEY "" CACHE STRING "Public Serval SID key used to sign upgrade manifest (required)")
  set(COMMOTIOND_SOCKET "/var/run/commotiond.sock" CACHE FILEPATH "Management socket of commotiond
    instance")

  if(MAKE_BUNDLES)
    file(COPY "${UPGRADES_DIR}" DESTINATION "${CMAKE_CURRENT_BINARY_DIR}")
    
    # prepare upgrade package
    if(SIGN_UPGRADE AND PUBLIC_KEY)
      if(KEYRING)
        message(STATUS "Creating signed upgrade package using key ${PUBLIC_KEY} in keyring 
          ${KEYRING}...")
        execute_process(
	        COMMAND "${PROJECT_SOURCE_DIR}/upgrade-builder.sh" prepare -v -d 
            "${CMAKE_CURRENT_BINARY_DIR}/upgrades" -o "${CMAKE_CURRENT_BINARY_DIR}/upgrades.tar.gz" 
            -s "${PUBLIC_KEY}" -b "${COMMOTIOND_SOCKET}" -k "${KEYRING}"
	        RESULT_VARIABLE EXEC_SUCCESS
        )
      else()
        message(STATUS "Creating signed upgrade package using key ${PUBLIC_KEY} in default 
          keyring...")
        execute_process(
	        COMMAND "${PROJECT_SOURCE_DIR}/upgrade-builder.sh" prepare -v -d 
            "${CMAKE_CURRENT_BINARY_DIR}/upgrades" -o "${CMAKE_CURRENT_BINARY_DIR}/upgrades.tar.gz" 
            -s "${PUBLIC_KEY}" -b "${COMMOTIOND_SOCKET}"
	        RESULT_VARIABLE EXEC_SUCCESS
        )
      endif()
    else()
      message(STATUS "Creating unsigned upgrade package...")
      execute_process(
        COMMAND "${PROJECT_SOURCE_DIR}/upgrade-builder.sh" prepare -v -d 
          "${CMAKE_CURRENT_BINARY_DIR}/upgrades" -o "${CMAKE_CURRENT_BINARY_DIR}/upgrades.tar.gz"
        RESULT_VARIABLE EXEC_SUCCESS
      )
    endif()
    if(NOT EXEC_SUCCESS EQUAL 0)
      message(FATAL_ERROR "Error: Failed to create upgrade package!")
    endif()
    
    if(BUILD_IMAGES)
      add_custom_target(bundle ALL
        COMMAND "${PROJECT_SOURCE_DIR}/upgrade-builder.sh" build -v -p 
          "${CMAKE_CURRENT_BINARY_DIR}/upgrades.tar.gz" -d 
          "${CMAKE_CURRENT_BINARY_DIR}/bin/${TARGET}/${SUBTARGET}" -r "${COMMOTION_VERSION}"
        DEPENDS image_builder
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        COMMENT "Bundling release images..." VERBATIM
      )
    endif()
  endif()
endif()
