##################################################################################################
# FILE: CMakelists.txt
# DESCRIPTION: The main CMake file for building Commotion Router images.
# 
# Copyright (c) 2014, Josh King
#
# This file is part of Commotion-Build.
# 
# Commotion-Build is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# Commotion-Build is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with Commotion-Build.  If not, see <http://www.gnu.org/licenses/>.
##################################################################################################

##################################################################################################
# PROJECT
##################################################################################################
cmake_minimum_required(VERSION 3.0.2)

include(ImageBuilder.cmake)

#Hide unnecessary cache variables for cmake-gui
mark_as_advanced(CMAKE_C_COMPILER)
mark_as_advanced(CMAKE_CXX_COMPILER)
mark_as_advanced(CMAKE_INSTALL_PREFIX)

#Set up project
project(commotion-build VERSION 1.1.0 LANGUAGES NONE)

##################################################################################################
# GLOBALS
##################################################################################################
#Set up variables for cache configuration
set(DEBUG OFF CACHE BOOL "Create verbose Makefile output")
set(COMMOTION_VERSION "1.1" CACHE STRING "Commotion version number")
set(COMMOTION_RELEASE "grumpy_cat" CACHE STRING "Commotion release nickname")
set(SKIP_MD5 OFF CACHE BOOL "Skip MD5 checking of downloaded ImageBuilder file")
set(COMMOTION_PACKAGES "commotion;commotion-gui" CACHE INTERNAL "Commotion default packages")
set(OPENWRT_VERSION "12.09" CACHE INTERNAL "OpenWRT version number")
set(OPENWRT_RELEASE "attitude_adjustment" CACHE INTERNAL "OpenWRT release nickname")

#Verbose Makefile
if(DEBUG)
  set(CMAKE_VERBOSE_MAKEFILE ON)
endif()

#Router default files
set(CONFIGS_DIR "${PROJECT_SOURCE_DIR}/configs")
set(FILES_DIR "${PROJECT_SOURCE_DIR}/files")

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
  if(IS_DIRECTORY "${CONFIG_PATH}/files")
    file(COPY ${CONFIG_PATH}/files/ DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
  endif()
endmacro()

##################################################################################################
# SETUP
##################################################################################################

#Copy default configuration files
if(IS_DIRECTORY ${FILES_DIR})
  file(COPY ${FILES_DIR}/ DESTINATION ${CMAKE_CURRENT_BINARY_DIR}/files)
endif()

#Get list of available router configs and select one in cache
config_list(CONFIG_LIST ${CONFIGS_DIR})
set(CONFIG "ubnt" CACHE STRING "Commotion Router configuration")
set_property(CACHE CONFIG PROPERTY STRINGS "${CONFIG_LIST}")
choose_config("${CONFIGS_DIR}/${CONFIG}")

#Create list of all packages to include in images
if(DEFINED PACKAGES)
  list(APPEND ALL_PACKAGES ${COMMOTION_PACKAGES} ${PACKAGES})
else()
  set(ALL_PACKAGES "${COMMOTION_PACKAGES}")
endif()

#Convert packages list to string
string(REPLACE ";" " " PACKAGES_STRING "${ALL_PACKAGES}")

#Write version identification files
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/files/openwrt_version "${COMMOTION_VERSION}")
file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/files/openwrt_release "${COMMOTION_RELEASE}")

#Add Commotion package repository to repositories.conf
set(REPO_CONF "${CMAKE_CURRENT_BINARY_DIR}/repositories.conf")
configure_file("${PROJECT_SOURCE_DIR}/repositories.conf.in" "${REPO_CONF}")

##################################################################################################
# BUILD
##################################################################################################
#Call Imagebuilder
imagebuild(RELEASE "${OPENWRT_RELEASE}" VERSION "${OPENWRT_VERSION}" TARGET "${TARGET}" 
  SUBTARGET "${SUBTARGET}" FILES "${CMAKE_CURRENT_BINARY_DIR}/files" 
  PACKAGES "${PACKAGES_STRING}" PROFILE "${PROFILE}" SKIP_MD5 ${OPENWRT_MD5} 
  REPO_CONF "${REPO_CONF}")
