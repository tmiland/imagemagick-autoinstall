#!/usr/bin/env bash


## Author: Tommy Miland (@tmiland) - Copyright (c) 2019


######################################################################
####                    ImageMagick AutoInstall                       ####
####            Automatic install script for ImageMagick              ####
####                   Maintained by @tmiland                     ####
######################################################################


version="1.0.0"

#------------------------------------------------------------------------------#
#
# MIT License
#
# Copyright (c) 2019 Tommy Miland
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
#------------------------------------------------------------------------------#
## Uncomment for debugging purpose
#set -o errexit
#set -o pipefail
#set -o nounset
#set -o xtrace

# Detect absolute and full path as well as filename of this script
cd "$(dirname $0)"
CURRDIR=$(pwd)
SCRIPT_FILENAME=$(basename $0)
cd - > /dev/null
sfp=$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || greadlink -f "${BASH_SOURCE[0]}" 2>/dev/null)
if [ -z "$sfp" ]; then sfp=${BASH_SOURCE[0]}; fi
SCRIPT_DIR=$(dirname "${sfp}")

# Repo name
REPO_NAME="tmiland/imagemagick-autoinstall"
# ImageMagick 6 Repo name
IMAGEMAGICK6_REPO="ImageMagick/ImageMagick6"
# ImageMagick 7 Repo name
IMAGEMAGICK7_REPO="ImageMagick/ImageMagick"

# Script name
SCRIPT_NAME="imagemagick-autoinstall.sh"
# Set update check
UPDATE_SCRIPT="check"
# ImageMagick 6 version (Enabled, latest release from GitHub not working)
IMAGICK_VER="6.9.10-51"
# ImageMagick 7 version (Disabled, get latest release from GitHub)
#IMAGICK_SEVEN_VER="7.0.8-51"

# Distro support
if ! lsb_release -si >/dev/null 2>&1; then
  if [[ -f /etc/debian_version ]]; then
    DISTRO=$(cat /etc/issue.net)
  elif [[ -f /etc/redhat-release ]]; then
    DISTRO=$(cat /etc/redhat-release)
  fi

  case "$DISTRO" in
    Debian*)
      PKGCMD="apt-get"
      LSB=lsb-release
      ;;
    Ubuntu*)
      PKGCMD="apt"
      LSB=lsb-release
      ;;
    CentOS*)
      PKGCMD="yum"
      LSB=redhat-lsb
      ;;
    Fedora*)
      PKGCMD="dnf"
      LSB=redhat-lsb
      ;;
    *) echo -e "${RED}${ERROR} unknown distro: '$DISTRO'${NC}" ; exit 1 ;;
  esac

  echo ""
  echo -e "${RED}${ERROR} Looks like ${LSB} is not installed!${NC}"
  echo ""
  read -p "Do you want to download ${LSB}? [y/n]? " answer
  echo ""

  case $answer in
    [Yy]* )
      echo -e "${GREEN}${ARROW} Installing ${LSB} on ${DISTRO}...${NC}"
      # Make sure that the script runs with root permissions
      if [[ "$EUID" != 0 ]]; then
        echo -e "${RED}${ERROR} This action needs root permissions.${NC} Please enter your root password...";
        su -s "$(which bash)" -c "${PKGCMD} install -y ${LSB}"
      else
        echo -e "${RED}${ERROR} Error: could not install ${LSB}!${NC}"
      fi
      echo -e "${GREEN}${DONE} Done${NC}"
      sleep 3
      cd ${CURRDIR}
      ./${SCRIPT_FILENAME}
      ;;
    [Nn]* )
      exit 1;
      ;;
    * ) echo "Enter Y, N, please." ;;
  esac
fi

SUDO=""
UPDATE=""
INSTALL=""
UNINSTALL=""
PURGE=""
CLEAN=""
PKGCHK=""
if [[ $(lsb_release -si) == "Debian" || $(lsb_release -si) == "Ubuntu" ]]; then
  export DEBIAN_FRONTEND=noninteractive
  # ImageMagick package name
  IMAGICKPKG=imagemagick
  SUDO="sudo"
  UPDATE="apt-get -o Dpkg::Progress-Fancy="1" update -qq"
  INSTALL="apt-get -o Dpkg::Progress-Fancy="1" install -qq"
  UNINSTALL="apt-get -o Dpkg::Progress-Fancy="1" remove -qq"
  PURGE="apt-get purge -o Dpkg::Progress-Fancy="1" -qq"
  CLEAN="apt-get clean && apt-get autoremove -qq"
  PKGCHK="dpkg -s"
  # Build-dep packages
  BUILD_DEP_PKGS="build-essential"
elif [[ $(lsb_release -si) == "CentOS" ]]; then
  # ImageMagick package name
  IMAGICKPKG=ImageMagick
  SUDO="sudo"
  UPDATE="yum update -q"
  INSTALL="yum install -y -q"
  UNINSTALL="yum remove -y -q"
  PURGE="yum purge -y -q"
  CLEAN="yum clean all -y -q"
  PKGCHK="rpm --quiet --query"
  # Build-dep packages
  BUILD_DEP_PKGS="ImageMagick-devel"
elif [[ $(lsb_release -si) == "Fedora" ]]; then
  SUDO="sudo"
  UPDATE="dnf update -q"
  INSTALL="dnf install -y -q"
  UNINSTALL="dnf remove -y -q"
  PURGE="dnf purge -y -q"
  CLEAN="dnf clean all -y -q"
  PKGCHK="rpm --quiet --query"
  # Build-dep packages
  BUILD_DEP_PKGS="ImageMagick-devel"
else
  echo -e "${RED}${ERROR} Error: Sorry, your OS is not supported.${NC}"
  exit 1;
fi

# Icons used for printing
ARROW='➜'
DONE='✔'
ERROR='✗'
WARNING='⚠'
# Colors used for printing
RED='\033[0;31m'
BLUE='\033[0;34m'
BBLUE='\033[1;34m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
DARKORANGE="\033[38;5;208m"
CYAN='\033[0;36m'
DARKGREY="\033[48;5;236m"
NC='\033[0m' # No Color
# Text formatting used for printing
BOLD="\033[1m"
DIM="\033[2m"
UNDERLINED="\033[4m"
INVERT="\033[7m"
HIDDEN="\033[8m"

# Make sure that the script runs with root permissions
chk_permissions() {
  if [[ "$EUID" != 0 ]]; then
    echo -e "${RED}${ERROR} This action needs root permissions.${NC} Please enter your root password...";
    cd "$CURRDIR"
    su -s "$(which bash)" -c "./$SCRIPT_FILENAME"
    cd - > /dev/null

    exit 0;
  fi
}

##
# Download files
##
download_file () {
  declare -r url=$1
  declare -r tf=$(mktemp)
  local dlcmd=''
  dlcmd="wget -O $tf"
  $dlcmd "${url}" &>/dev/null && echo "$tf" || echo '' # return the temp-filename (or empty string on error)
}
##
# Open files
##
open_file () { #expects one argument: file_path
  if [ "$(uname)" == 'Darwin' ]; then
    open "$1"
  elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    xdg-open "$1"
  else
    echo -e "${RED}${ERROR} Error: Sorry, opening files is not supported for your OS.${NC}"
  fi
}

# ImageMagick

# Get latest ImageMagick 6 release tag (Not working)
# get_latest_imagemagick6_release() {
#   curl --silent "https://api.github.com/repos/$1/releases/latest" |
#   grep -oP '"tag_name": "\K(.*)(?=")'
# }
# 
# IMAGICK_VER=$(get_latest_imagemagick6_release ${IMAGEMAGICK6_REPO})

# Get latest ImageMagick 7 release tag
get_latest_imagemagick7_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep -oP '"tag_name": "\K(.*)(?=")'
}

IMAGICK_SEVEN_VER=$(get_latest_imagemagick7_release ${IMAGEMAGICK7_REPO})

# Get latest release tag from GitHub
get_latest_release_tag() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep '"tag_name":' |
  sed -n 's/[^0-9.]*\([0-9.]*\).*/\1/p'
}

RELEASE_TAG=$(get_latest_release_tag ${REPO_NAME})

# Get latest release download url
get_latest_release() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep '"browser_download_url":' |
  sed -n 's#.*\(https*://[^"]*\).*#\1#;p'
}

LATEST_RELEASE=$(get_latest_release ${REPO_NAME})

# Get latest release notes
get_latest_release_note() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep '"body":' |
  sed -n 's/.*"\([^"]*\)".*/\1/;p'
}

RELEASE_NOTE=$(get_latest_release_note ${REPO_NAME})

# Get latest release title
get_latest_release_title() {
  curl --silent "https://api.github.com/repos/$1/releases/latest" |
  grep -m 1 '"name":' |
  sed -n 's/.*"\([^"]*\)".*/\1/;p'
}

RELEASE_TITLE=$(get_latest_release_title ${REPO_NAME})

# Header
header() {
  echo -e "${GREEN}\n"
  echo ' ╔═══════════════════════════════════════════════════════════════════╗'
  echo ' ║                      '${SCRIPT_NAME}'                   ║'
  echo ' ║                Automatic install script for ImageMagick           ║'
  echo ' ║                      Maintained by @tmiland                       ║'
  echo ' ║                          version: '${version}'                           ║'
  echo ' ╚═══════════════════════════════════════════════════════════════════╝'
  echo -e "${NC}"
  echo -e ""
}

# Update banner
show_update_banner () {
  header
  echo "Welcome to the ${SCRIPT_NAME} script."
  echo ""
  echo "There is a newer version of ${SCRIPT_NAME} available."
  echo ""
  echo ""
  echo -e "${GREEN}${DONE} New version:${NC} "${RELEASE_TAG}" - ${RELEASE_TITLE}"
  echo ""
  echo -e "${ORANGE}${ARROW} Notes:${NC}\n"
  echo -e "${BLUE}${RELEASE_NOTE}${NC}"
  echo ""
}
##
# Returns the version number of ${SCRIPT_NAME} file on line 14
##
get_updater_version () {
  echo $(sed -n '14 s/[^0-9.]*\([0-9.]*\).*/\1/p' "$1")
}
##
# Update script
##
# Default: Check for update, if available, ask user if they want to execute it
update_updater () {
  echo -e "${GREEN}${ARROW} Checking for updates...${NC}"
  # Get tmpfile from github
  declare -r tmpfile=$(download_file "$LATEST_RELEASE")
  if [[ $(get_updater_version "${SCRIPT_DIR}/$SCRIPT_FILENAME") < "${RELEASE_TAG}" ]]; then
    if [ $UPDATE_SCRIPT = 'check' ]; then
      show_update_banner
      echo -e "${RED}${ARROW} Do you want to update [Y/N?]${NC}"
      read -p "" -n 1 -r
      echo -e "\n\n"
      if [[ $REPLY =~ ^[Yy]$ ]]; then
        mv "${tmpfile}" "${SCRIPT_DIR}/${SCRIPT_FILENAME}"
        chmod u+x "${SCRIPT_DIR}/${SCRIPT_FILENAME}"
        "${SCRIPT_DIR}/${SCRIPT_FILENAME}" "$@" -d
        exit 1 # Update available, user chooses to update
      fi
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        return 1 # Update available, but user chooses not to update
      fi
    fi
  else
    echo -e "${GREEN}${DONE} No update available.${NC}"
    return 0 # No update available
  fi
}
##
# Ask user to update yes/no
##
if [ $# != 0 ]; then
  while getopts ":ud" opt; do
    case $opt in
      u)
        UPDATE_SCRIPT='yes'
        ;;
      d)
        UPDATE_SCRIPT='no'
        ;;
      \?)
        echo -e "${RED}\n ${ERROR} Error! Invalid option: -$OPTARG${NC}" >&2
        usage
        ;;
      :)
        echo -e "${RED}${ERROR} Error! Option -$OPTARG requires an argument.${NC}" >&2
        exit 1
        ;;
    esac
  done
fi

update_updater $@
cd "$CURRDIR"
# https://github.com/tmiland/latest-release

# Check which ImageMagick version is installed
chk_imagickpkg() {

  if [[ $(lsb_release -si) == "Debian" || $(lsb_release -si) == "Ubuntu" ]]; then
    apt -qq list $IMAGICKPKG 2>/dev/null
  elif [[ $(lsb_release -si) == "CentOS" || $(lsb_release -si) == "Fedora" ]]; then
    if [[ $(identify -version 2>/dev/null) ]]; then
      identify -version
    else
      echo -e "${ORANGE}${ERROR} ImageMagick is not installed.${NC}"
    fi
  else
    echo -e "${RED}${ERROR} Error: Sorry, your OS is not supported.${NC}"
    exit 1;
  fi
}

# Exit Script
exit_script() {
  header
  echo -e "
   This script runs on coffee ☕

   ${GREEN}${DONE}${NC} ${BBLUE}Paypal${NC} ${ARROW} ${ORANGE}https://paypal.me/milanddata${NC}
   ${GREEN}${DONE}${NC} ${BBLUE}BTC${NC}    ${ARROW} ${ORANGE}3MV69DmhzCqwUnbryeHrKDQxBaM724iJC2${NC}
   ${GREEN}${DONE}${NC} ${BBLUE}BCH${NC}    ${ARROW} ${ORANGE}qznnyvpxym7a8he2ps9m6l44s373fecfnv86h2vwq2${NC}
  "
  echo -e "Documentation for this script is available here: ${ORANGE}\n${ARROW} https://github.com/${REPO_NAME}${NC}\n"
  echo -e "${ORANGE}${ARROW} Goodbye.${NC} ☺"
  echo ""
  exit
}

main() {
  echo ""
  echo "Choose your Imagemagick version :"
  echo -e "   1) System's Imagemagick\n "
  echo -e "   ($(chk_imagickpkg)) \n"
  echo    "   2) Imagemagick $IMAGICK_VER from source"
  echo    "   3) Imagemagick $IMAGICK_SEVEN_VER from source"
  echo    "   4) Exit"
  echo ""
  while [[ $IMAGICK != "1" && $IMAGICK != "2" && $IMAGICK != "3" && $IMAGICK != "4" ]]; do
    read -p "Select an option [1-4]: " IMAGICK
  done

  case $IMAGICK in
    2)
      IMAGEMAGICK=y
      ;;
    3)
      IMAGEMAGICK_SEVEN=y
      ;;
    4)
      exit_script
      ;;
  esac
  echo ""
  read -n1 -r -p "ImageMagick is ready to be installed, press any key to continue..."
  echo ""

  # ImageMagick 6
  if [[ "$IMAGEMAGICK" = 'y' ]]; then

    if ! ${PKGCHK} $BUILD_DEP_PKGS >/dev/null 2>&1; then
      for i in $BUILD_DEP_PKGS; do
        ${INSTALL} $i 2> /dev/null # || exit 1
      done
    fi

    if [[ $(lsb_release -si) == "Debian" || $(lsb_release -si) == "Ubuntu" ]]; then
      ${SUDO} ${PURGE} imagemagick
      ${SUDO} ${CLEAN}
    elif [[ $(lsb_release -si) == "CentOS" || $(lsb_release -si) == "Fedora" ]]; then
      ${SUDO} yum groupinstall "Development Tools"
    else
      echo -e "${RED}${ERROR} Error: Sorry, your OS is not supported.${NC}"
      exit 1;
    fi

    cd /tmp || exit 1
    wget https://github.com/ImageMagick/ImageMagick6/archive/${IMAGICK_VER}.tar.gz
    tar -xvf ${IMAGICK_VER}.tar.gz
    cd ImageMagick6-${IMAGICK_VER}

    ./configure
    make
    ${SUDO} make install

    ${SUDO} ldconfig /usr/local/lib

    identify -version
    sleep 5

    rm -r /tmp/ImageMagick6-${IMAGICK_VER}
    rm -r /tmp/${IMAGICK_VER}.tar.gz

  fi

  # ImageMagick 7
  if [[ "$IMAGEMAGICK_SEVEN" = 'y' ]]; then
    if ! ${PKGCHK} $BUILD_DEP_PKGS >/dev/null 2>&1; then
      for i in $BUILD_DEP_PKGS; do
        ${INSTALL} $i
      done
    fi

    if [[ $(lsb_release -si) == "Debian" || $(lsb_release -si) == "Ubuntu" ]]; then
      ${SUDO} ${PURGE} imagemagick
      ${SUDO} ${CLEAN}
    elif [[ $(lsb_release -si) == "CentOS" || $(lsb_release -si) == "Fedora" ]]; then
      ${SUDO} yum groupinstall "Development Tools"
    else
      echo -e "${RED}${ERROR} Error: Sorry, your OS is not supported.${NC}"
      exit 1;
    fi

    cd /tmp || exit 1
    wget https://www.imagemagick.org/download/ImageMagick-${IMAGICK_SEVEN_VER}.tar.gz
    #wget https://github.com/ImageMagick/ImageMagick/archive/${IMAGICK_SEVEN_VER}.tar.gz
    tar -xvf ImageMagick-${IMAGICK_SEVEN_VER}.tar.gz
    cd ImageMagick-${IMAGICK_SEVEN_VER}

    ./configure
    make
    ${SUDO} make install

    ${SUDO} ldconfig /usr/local/lib

    identify -version
    sleep 5

    rm -r /tmp/ImageMagick-${IMAGICK_SEVEN_VER}
    rm -r /tmp/ImageMagick-${IMAGICK_SEVEN_VER}.tar.gz

  fi

  if [[ $IMAGEMAGICK_SEVEN != "y" && $IMAGEMAGICK != "y" ]]; then
    if ! ${PKGCHK} $BUILD_DEP_PKGS >/dev/null 2>&1; then
      if [[ $(lsb_release -si) == "Debian" || $(lsb_release -si) == "Ubuntu" ]]; then
        ${SUDO} ${INSTALL} imagemagick
      elif [[ $(lsb_release -si) == "CentOS" || $(lsb_release -si) == "Fedora" ]]; then
        ${SUDO} ${INSTALL} ImageMagick
      else
        echo -e "${RED}${ERROR} Error: Sorry, your OS is not supported.${NC}"
        exit 1;
      fi
    fi
  fi
  echo -e "${GREEN}${DONE} ImageMagick has been successfully installed!${NC}"

}
header
chk_permissions
main $@
exit 0
