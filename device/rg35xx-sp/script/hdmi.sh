#!/bin/sh
# shellcheck disable=SC2034

. /opt/muos/script/var/func.sh

XDG_RUNTIME_DIR="/var/run"
HDMI_IN_USE="/tmp/hdmi_in_use"

DO_REFRESH() {
	printf "1" >"/tmp/hdmi_do_refresh"
	/opt/muos/extra/murefresh
}

SET_AUDIO() {
	case "$1" in
		EXT) NID="$(GET_VAR audio nid_external)" ;;
		INT) NID="$(GET_VAR audio nid_internal)" ;;
		*)
			printf "Error: Invalid argument for audio: %s\n" "$1" >&2
			exit 1
			;;
	esac
	wpctl set-default "$NID"
	[ "$1" = "EXT" ] && wpctl set-volume "$NID" 100%
}

SET_DISPLAY_PARAMS() {
	printf "4 "
	printf "%s " "$(GET_VAR global settings/hdmi/resolution)"
	printf "%s " "$(GET_VAR global settings/hdmi/space)"
	printf "%s " "$(GET_VAR global settings/hdmi/depth)"
	printf "0x4 "
	printf "0x201 "
	printf "0 "
	printf "%s " "$(GET_VAR global settings/hdmi/range)"
	printf "%s " "$(GET_VAR global settings/hdmi/scan)"
	printf "8"
}

case "$1" in
	start)
		if [ "$(GET_VAR global settings/hdmi/audio)" -eq 0 ]; then
			SET_AUDIO "EXT"
		else
			SET_AUDIO "INT"
		fi
		HDMI_SWITCH
		DISPLAY_WRITE disp0 switch1 "$(SET_DISPLAY_PARAMS)"
		DO_REFRESH

		printf "1" >"$HDMI_IN_USE"
		;;
	stop)
		SET_AUDIO "INT"
		FB_SWITCH "$(GET_VAR device screen/internal/width)" "$(GET_VAR device screen/internal/height)" 32
		DISPLAY_WRITE disp0 switch "1 0"
		DO_REFRESH

		printf "0" >"$HDMI_IN_USE"
		;;
	*)
		printf "Usage: %s {start|stop}\n" "$0"
		exit 1
		;;
esac