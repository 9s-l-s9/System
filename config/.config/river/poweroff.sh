#!/bin/sh
# poweroff prompt, intended to be launched by pressing the powerbutton. Requires
# that logind does not handle the powerbutton.
if wayprompt --title "Turn off device?" --button-ok "Yes" --button-cancel "No"
then
	/usr/bin/poweroff
fi
