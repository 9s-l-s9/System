#!/bin/bash
shopt -s lastpipe
slurp -d -w 4 -b '#00000044' -c '#ff0000' | read GEO
if [ $? -eq 0 ]
then
	grim -g "${GEO}" -t png - | wl-copy
fi
