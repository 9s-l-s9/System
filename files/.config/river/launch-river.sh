#!/bin/sh --login

export MOZ_ENABLE_WAYLAND=1
export CLUTTER_BACKEND=wayland
export QT_QPA_PLATFORM=wayland
export ECORE_EVAS_ENGINE=wayland-egl
export ELM_ENGINE=wayland_egl
export SDL_VIDEODRIVER=wayland
export _JAVA_AWT_WM_NONREPARENTING=1
export NO_AT_BRIDGE=1

export XDG_SESSION_TYPE=wayland
export XDG_SESSION_DESKTOP=river
export XDG_CURRENT_DESKTOP=river

exec systemd-cat --identifier=river river $@
