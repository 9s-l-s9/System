#!/bin/bash

swaybg --image '/home/samuel/images/wallpaper/1.png' -m fill&

function handle {
    if [[ ${1:0:9} == "workspace" ]]; then
        newimag='/home/samuel/images/wallpaper/'${1: -1}'.png'
        swaybg --image $newimag -m fill&
    fi
}

socat - UNIX-CONNECT:/tmp/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock | while read line; do handle $line; done
