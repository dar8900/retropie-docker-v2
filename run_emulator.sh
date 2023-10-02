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

usage()
{
	print_message "Usage: $0 <conf file> <docker image>" info
}


CONF_FILE=$1
DOCKER_IMG=$2

if [ ! -f "$CONF_FILE" ];then
	print_message "Config file missing" error
	usage
	exit 1
fi

check_docker_image=$(docker image inspect "$DOCKER_IMG" 1>/dev/null 2>&1)

RET=$?

if [ -z "$DOCKER_IMG" ] || [ "$RET" -ne 0 ];then
	print_message "Docker image name missing or wrong" error
	usage
	exit 1
fi

source "$CONF_FILE"

variables=("ROMS_DIR" "BIOS_DIR" "CONFIG_DIR" "RETROARCH_AUTOCONF" "EMU_CONF")


verifica_o_crea_directory() {
    var_name="$1"
    dir_path="${!var_name}"

    if [ -z "$dir_path" ]; then
        print_message "$var_name parameter missing" error
        exit 1
    elif [ ! -d "$dir_path" ]; then
        mkdir -p "$dir_path"
    fi
}

for var in "${variables[@]}"; do
    verifica_o_crea_directory "$var"
done

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
	--privileged "$DOCKER_IMG"
