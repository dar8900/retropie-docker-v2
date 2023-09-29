#!/bin/bash

print_message() {
    declare -A colors
    colors["error"]='\e[31m'
    colors["info"]='\e[33m'
    colors["ok"]='\e[32m'
    NO_COLOR='\e[0m'

    MESSAGE=$1
    LEVEL=$(echo "$2" | awk '{print tolower($0)}')

    MSG_COLOR=${colors[$LEVEL]}

    echo -e "${MSG_COLOR}$MESSAGE${NO_COLOR}"
}


CONF_FILE="runner_conf.conf"

if [ ! -f "$CONF_FILE" ];then
	print_message "Config file missing" error
	exit 1
fi

source "$CONF_FILE"


if [ -z "$ROMS_DIR" ];then
    print_message "ROMS_DIR parameter missing" error
    exit 1
elif [ ! -d "$ROMS_DIR" ];then
	mkdir -p "$ROMS_DIR"
fi

if [ -z "$BIOS_DIR" ];then
    print_message "BIOS_DIR parameter missing" error
    exit 1
elif [ ! -d "$BIOS_DIR" ];then
	mkdir -p "$BIOS_DIR"
fi

if [ -z "$CONFIG_DIR" ];then
    print_message "CONFIG_DIR parameter missing" error
    exit 1
elif [ ! -d "$CONFIG_DIR" ];then
	mkdir -p "$CONFIG_DIR"
fi

if [ -z "$RETROARCH_AUTOCONF" ];then
    print_message "RETROARCH_AUTOCONF parameter missing" error
    exit 1
elif [ ! -d "$RETROARCH_AUTOCONF" ];then
	mkdir -p "$RETROARCH_AUTOCONF"
fi

if [ -z "$EMU_CONF" ];then
    print_message "EMU_CONF parameter missing" error
    exit 1
elif [ ! -d "$EMU_CONF" ];then
	mkdir -p "$EMU_CONF"
fi


xhost local:docker
docker run -it --rm -e XDG_RUNTIME_DIR  -e DBUS_SESSION_BUS_ADDRESS \
	-e DISPLAY=unix$DISPLAY \
	-v /dev/bus:/dev/bus -v /dev/input:/dev/input \
	-v /dev/uinput:/dev/uinput -v /dev/event:/dev/event \
	-v /dev/snd:/dev/snd -v /tmp/.X11-unix:/tmp/.X11-unix \
	-v "$ROMS_DIR":/home/pi/RetroPie/roms/ \
	-v "$BIOS_DIR":/home/pi/RetroPie/BIOS/ \
	-v "$CONFIG_DIR":/home/pi/.emulationstation/ \
	-v "$RETROARCH_AUTOCONF":/opt/retropie/configs/all/retroarch/autoconfig/ \
	-v "$EMU_CONF":/opt/retropie/configs/all/emulationstation/ \
	-v /run/user/$(id -u):/run/user/$(id -u) -v /var/run/dbus:/var/run/dbus \
	-v /run/udev:/run/udev -v /var/run/docker.sock:/var/run/docker.sock \
	--device /dev/bus --device /dev/input --device /dev/uinput \
	--device /dev/event --device /dev/snd \
	--privileged retropie-docker
