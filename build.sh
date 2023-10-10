#! /bin/bash

BUILD_DIR=`pwd`
APP_DIR="${BUILD_DIR}/build/application"
CONFIG_SERVICE_APP_DIR="${APP_DIR}/fibo_config_service"
CONFIG_SERVICE_APP_PATH="${APP_DIR}/fibo_config_service/fibo_config*"
FLASH_SERVICE_APP_PATH="${APP_DIR}/fibo_flash_service/fibo_flash*"
FLASH_SERVICE_APP_DIR="${APP_DIR}/fibo_flash_service"
HELPER_SERVICE_APP_PATH="${APP_DIR}/fibo_helper_service/fibo_helper*"
MA_SERVICE_PATH_APP_DIR="${APP_DIR}/fibo_ma_service"
MA_SERVICE_PATH_APP_PATH="${BUILD_DIR}/application/fibo_ma_service/fibo_ma"
MA_SERVICE_PATH_SCRIPT_PATH="${BUILD_DIR}/application/fibo_ma_service/"


DEB_SOFT_DIR="${BUILD_DIR}/release/dpkg/opt/fibocom"
DEB_CONFIG_SERVICE_DIR="${DEB_SOFT_DIR}/fibo_config_service"
DEB_FLASH_SERVICE_DIR="${DEB_SOFT_DIR}/fibo_flash_service"
DEB_HELPER_SERVICE_DIR="${DEB_SOFT_DIR}/fibo_helper_service"
#DEB_MA_SERVICE_SCRIPT_PATH="${BUILD_DIR}/release/dpkg/usr/lib/x86_64-linux-gnu/ModemManager/fcc-unlock.d"
DEB_MA_SERVICE_DIR="${DEB_SOFT_DIR}/fibo_ma_service"

OEMUSBID_LIST=(2cb7:01a2 2cb7:0301 413c:8209 413c:8211 413c:8213 413c:8215)

BUILD_LIST=(
    build_all
    clean_project
)

function operation_menu_select()
{
    echo -e "\033[32m=================================================== \033[0m"
    echo -e "\033[35m operation select:\033[0m"
    for list in ${BUILD_LIST[@]}; do
        echo -e "\033[32m    --------------------------------- \033[0m"
        COUNT=$(($COUNT+1)); echo -e "\033[35m    $COUNT.$list \033[0m"
    done
}

function delete_lib_build_file()
{
    rm -rf ${BUILD_DIR}/application/3rd/iniparser/src/*.o
    rm -rf ${BUILD_DIR}/application/3rd/iniparser/libini*

    rm -rf ${BUILD_DIR}/application/3rd/safestringlib/build/

    rm -rf ${BUILD_DIR}/application/3rd/qdl/*.o
    rm -rf ${BUILD_DIR}/application/3rd/qdl/qdl ${BUILD_DIR}/application/3rd/qdl/ks
}
function copy_libfile()
{
    # copy iniparser lib
    mkdir -p ${BUILD_DIR}/build/application/iniparser
    cp -raf ${BUILD_DIR}/application/3rd/iniparser/*.a ${BUILD_DIR}/build/application/iniparser/
    cp -raf ${BUILD_DIR}/application/3rd/iniparser/src/*.h ${BUILD_DIR}/build/application/iniparser/
    #copy safestringlib
    mkdir -p ${BUILD_DIR}/build/application/safestringlib
    cp -raf ${BUILD_DIR}/application/3rd/safestringlib/build/*.a ${BUILD_DIR}/build/application/safestringlib/
    cp -raf ${BUILD_DIR}/application/3rd/safestringlib/include/*.h ${BUILD_DIR}/build/application/safestringlib/

    mkdir -p ${BUILD_DIR}/build/application/qdl
    cp -raf ${BUILD_DIR}/application/3rd/qdl/qdl ${BUILD_DIR}/build/application/qdl/
    delete_lib_build_file
}

function code_build()
{
   if [ -d "build" ];then
       rm -r build
   fi
    mkdir build
    cd build
    cmake ..
    copy_libfile
    cmake --build .
}

function build_iniparser()
{
    cd ${BUILD_DIR}/application/3rd/iniparser
    make
    cd ${BUILD_DIR}
}

function build_safestringlib()
{
    cd ${BUILD_DIR}/application/3rd/safestringlib
    cmake -S . -B build && cd build
    make 
    cd ${BUILD_DIR}
}

function build_qdl()
{
    cd ${BUILD_DIR}/application/3rd/qdl
    make
    cd ${BUILD_DIR}
}

function build_service()
{
    
    build_iniparser
    build_safestringlib
    build_qdl
    code_build
}

function copy_file_to_deb_directory()
{
    # copy configservice file
    if [ "$(ls -A $DEB_CONFIG_SERVICE_DIR)" ]; then
        rm -r ${DEB_CONFIG_SERVICE_DIR}/*
    fi
    cp -raf ${CONFIG_SERVICE_APP_DIR}/fbwwanConfig.ini ${DEB_CONFIG_SERVICE_DIR}
    cp -raf ${CONFIG_SERVICE_APP_PATH} ${DEB_CONFIG_SERVICE_DIR}
    

    # copy flashservice file
    if [ "$(ls -A $DEB_FLASH_SERVICE_DIR)" ]; then
        rm -r ${DEB_FLASH_SERVICE_DIR}/*
    fi
    cp -raf ${FLASH_SERVICE_APP_PATH} ${DEB_FLASH_SERVICE_DIR}
    cp -raf ${FLASH_SERVICE_APP_DIR}/*.ini ${DEB_FLASH_SERVICE_DIR}

    # copy helperservice
    if [ "$(ls -A $DEB_HELPER_SERVICE_DIR)" ]; then
        path=`pwd`
        cd $DEB_HELPER_SERVICE_DIR
        ls | grep -v  fibo_helper_tools  | awk  '{system("rm -rf "$1)}'
        cd $path
    fi
    cp -raf ${HELPER_SERVICE_APP_PATH} ${DEB_HELPER_SERVICE_DIR}

    # copy maservice
    if [ -d $DEB_MA_SERVICE_DIR ]; then
        #rm -r ${DEB_MA_SERVICE_DIR}/*
        cp -raf ${MA_SERVICE_PATH_APP_PATH} ${DEB_MA_SERVICE_DIR}
        # creat fccunlock script dir
        # mkdir -p ${DEB_MA_SERVICE_SCRIPT_PATH}
        # copy fccunlcok script to dir
        # cp -raf ${MA_SERVICE_PATH_SCRIPT_PATH}/*:* ${DEB_MA_SERVICE_SCRIPT_PATH}
    fi

}



function clean_project()
{
    rm -rf ${BUILD_DIR}/build
    rm -rf ${BUILD_DIR}/release
}

function create_helper_conf()
{
    echo "<!DOCTYPE busconfig PUBLIC
 \"-//freedesktop//DTD D-BUS Bus Configuration 1.0//EN\"
 \"http://www.freedesktop.org/standards/dbus/1.0/busconfig.dtd\">
<busconfig>
  <!-- This config allows anyone to control mcdm -->

  <policy context=\"default\">
    <allow send_destination=\"com.fibocom.helper\"/>
  </policy>

  <policy user=\"root\">
    <allow own=\"com.fibocom.helper\"/>
  </policy>
</busconfig>" > $1/com.fibocom.helper.conf

}

function create_config_service()
{
    echo "[Unit]
Description=Firmware Config Service
After=ModemManager.service fibo_helper.service

[Service]
EnvironmentFile=/etc/systemd/system/fibo_config.d/env.conf
ExecStart=/opt/fibocom/fibo_config_service/fibo_config
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-abort
Type=simple
Restart=on-abort
User=root

[Install]
Alias=fibo_config
WantedBy=multi-user.target" > $1/fibo_config.service

}

function create_flash_service()
{
    echo "[Unit]
Description=Firmware Flash Service
After=ModemManager.service fibo_helper.service

[Service]
EnvironmentFile=/etc/systemd/system/fibo_flash.d/env.conf
ExecStart=/opt/fibocom/fibo_flash_service/fibo_flash
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-abort
Type=simple
Restart=on-abort
User=root

[Install]
Alias=fibo_flash
WantedBy=multi-user.target" > $1/fibo_flash.service

}

function create_helper_service()
{
    echo "[Unit]
Description=Firmware Helper Service
After=ModemManager.service

[Service]
EnvironmentFile=/etc/systemd/system/fibo_helper.d/env.conf
ExecStart=/opt/fibocom/fibo_helper_service/fibo_helperd
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-abort
Type=simple
Restart=on-abort
User=root

[Install]
Alias=fibo_helper
WantedBy=multi-user.target" > $1/fibo_helper.service

}

function create_helper_mbim_service()
{
    echo "[Unit]
Description=Firmware Helper Service
After=ModemManager.service fibo_helper.service

[Service]
EnvironmentFile=/etc/systemd/system/fibo_helper.d/env.conf
ExecStart=/opt/fibocom/fibo_helper_service/fibo_helperm
ExecReload=/bin/kill -HUP \$MAINPID
Restart=on-abort
Type=simple
Restart=on-abort
User=root

[Install]
Alias=fibo_helper_mbim
WantedBy=multi-user.target" > $1/fibo_helper_mbim.service

}

function create_config_d()
{
    echo "LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" > $1/env.conf

}

function create_flash_d()
{
    echo "LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" > $1/env.conf

}
function create_helper_d()
{
    echo "LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/lib" > $1/env.conf

}

function create_rule()
{
    echo "# do not edit this file, it will be overwritten on update
ACTION!=\"add|change|move|bind\", GOTO=\"mm_fibocom_linux_apps_port_types_end\"
SUBSYSTEMS==\"usb\", ATTRS{bInterfaceNumber}==\"?*\", ENV{.MM_USBIFNUM}=\"\$attr{bInterfaceNumber}\"

ATTRS{idVendor}==\"413c\", ATTRS{idProduct}==\"8213\", ENV{.MM_USBIFNUM}==\"02\", SUBSYSTEM==\"tty\", ENV{ID_MM_PORT_IGNORE}=\"1\"
ATTRS{idVendor}==\"413c\", ATTRS{idProduct}==\"8215\", ENV{.MM_USBIFNUM}==\"02\", SUBSYSTEM==\"tty\", ENV{ID_MM_PORT_IGNORE}=\"1\"

LABEL=\"mm_fibocom_linux_apps_port_types_end\"
" > $1/76-mm-fibocom-linux-apps-port-types.rules

}
function create_fcc_unlock()
{
    for s in ${OEMUSBID_LIST[@]}
    do
        echo "#!/bin/sh

# SPDX-License-Identifier: CC0-1.0
# 2023 Nero zhang <sinaro@sinaro.es>
#
# Fibocom FM101 FCC unlock mechanism
#

# run fcc-unlock binary
/opt/fibocom/fibo_ma_service/fibo_ma
exit $?" > $1/$s
    done

}

function create_and_install()
{
    if [ -d "${BUILD_DIR}/release" ];then
       rm -r ${BUILD_DIR}/release
    fi
    # create etc and file
    mkdir -p ${BUILD_DIR}/release/dpkg/etc/dbus-1/system.d/
    create_helper_conf ${BUILD_DIR}/release/dpkg/etc/dbus-1/system.d/
    
    mkdir -p ${BUILD_DIR}/release/dpkg/etc/systemd/system/
    create_config_service ${BUILD_DIR}/release/dpkg/etc/systemd/system/
    create_flash_service ${BUILD_DIR}/release/dpkg/etc/systemd/system/
    create_helper_service ${BUILD_DIR}/release/dpkg/etc/systemd/system/
    create_helper_mbim_service ${BUILD_DIR}/release/dpkg/etc/systemd/system/


    
    mkdir -p ${BUILD_DIR}/release/dpkg/etc/systemd/system/fibo_config.d/
    create_config_d ${BUILD_DIR}/release/dpkg/etc/systemd/system/fibo_config.d/
    mkdir -p ${BUILD_DIR}/release/dpkg/etc/systemd/system/fibo_flash.d/
    create_flash_d ${BUILD_DIR}/release/dpkg/etc/systemd/system/fibo_flash.d/
    mkdir -p ${BUILD_DIR}/release/dpkg/etc/systemd/system/fibo_helper.d/
    create_helper_d ${BUILD_DIR}/release/dpkg/etc/systemd/system/fibo_helper.d/

    #create fibocom and file
    mkdir -p ${BUILD_DIR}/release/dpkg/opt/fibocom/fibo_config_service/
    mkdir -p ${BUILD_DIR}/release/dpkg/opt/fibocom/fibo_flash_service/
    mkdir -p ${BUILD_DIR}/release/dpkg/opt/fibocom/fibo_helper_service/
    mkdir -p ${BUILD_DIR}/release/dpkg/opt/fibocom/fibo_helper_service/fibo_helper_tools/
    cp ${BUILD_DIR}/build/application/qdl/* ${BUILD_DIR}/release/dpkg/opt/fibocom/fibo_helper_service/fibo_helper_tools/
    mkdir -p ${BUILD_DIR}/release/dpkg/opt/fibocom/fibo_ma_service/

    #create lib and file
    mkdir -p ${BUILD_DIR}/release/dpkg/usr/lib/udev/rules.d/
    create_rule ${BUILD_DIR}/release/dpkg/usr/lib/udev/rules.d/
    mkdir -p ${BUILD_DIR}/release/dpkg/usr/lib/x86_64-linux-gnu/ModemManager/fcc-unlock.d
    create_fcc_unlock ${BUILD_DIR}/release/dpkg/usr/lib/x86_64-linux-gnu/ModemManager/fcc-unlock.d


}

function build_all()
{
    #build sourece code
    build_service
    # create release dir and create config files
    create_and_install
    # copy file to release
    copy_file_to_deb_directory
    # make_deb_file
}

#********************************<main start>********************************************#

OPERATOR_SELECT=$1
if [ "$OPERATOR_SELECT" == "" ] ; then
    COUNT=0; operation_menu_select
    echo -e "\033[32m=================================================== \033[0m"
    echo -en "\033[35m Please input a number in (1-$COUNT):\033[0m"
    read OPERATOR_SELECT
    echo -e "\033[32m=================================================== \033[0m"
fi


echo -e "\033[35m project: operator: $OPERATOR_SELECT \033[0m";
echo -e "\033[32m=================================================== \033[0m"


case $OPERATOR_SELECT in
    1) build_all ;;
    2) clean_project ;;
    *) COUNT=0; menu_select
       echo -e "\033[32m=================================================== \033[0m"
       echo -e "\033[31m ERROR: You must input a number in (1-$COUNT). \033[0m"
       echo -e "\033[32m=================================================== \033[0m"
       exit -1 ;;
esac

