#!/bin/bash

# This script changes network location based on the name of Wi-Fi network.

exec 2>&1 >> $HOME/Library/Logs/LocationChanger.log

sleep 3

ts() {
    date +"[%Y-%m-%d %H:%M] $*"
}

SSID=`/System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | grep ' SSID' | cut -d : -f 2- | sed 's/^[ ]*//'`

LOCATION_NAMES=`scselect | tail -n +2 | cut -d \( -f 2- | sed 's/)$//'`
CURRENT_LOCATION=`scselect | tail -n +2 | egrep '^\ +\*' | cut -d \( -f 2- | sed 's/)$//'`

ts "Connected to '$SSID'"

CONFIG_FILE=$HOME/.locations/locations.conf

if [ -f $CONFIG_FILE ]; then
    ESSID=`echo "$SSID" | sed 's/[.[\*^$]/\\\\&/g'`
    NEW_SSID=`grep "^$ESSID=" $CONFIG_FILE | cut -d = -f 2`
    if [ "$NEW_SSID" != "" ]; then
        MSG="Will switch the location to '$NEW_SSID' (configuration file)"
        ts $MSG

        SSID=$NEW_SSID
    else
        MSG="Will switch the location to '$SSID'"
        ts $MSG

    fi
fi

ESSID=`echo "$SSID" | sed 's/[.[\*^$]/\\\\&/g'`
if echo "$LOCATION_NAMES" | grep -q "^$ESSID$"; then
    NEW_LOCATION="$SSID"
else
    if echo "$LOCATION_NAMES" | grep -q "^Automatic$"; then
        NEW_LOCATION=Automatic
        MSG="Location '$SSID' was not found. Will default to 'Automatic'"
        ts $MSG
    else
        MSG="Location '$SSID' was not found. The following locations are available: $LOCATION_NAMES"
        ts $MSG
        exit 1
    fi
fi

if [ "$NEW_LOCATION" != "" ]; then
    if [ "$NEW_LOCATION" != "$CURRENT_LOCATION" ]; then
        MSG="Changing the location to '$NEW_LOCATION'"
        ts $MSG
        osascript -e "display notification \"$MSG\" with title \"Location switcher\" sound name \"Blow\""
        scselect "$NEW_LOCATION"
        SCRIPT="$HOME/.locations/$NEW_LOCATION"
        if [ -f "$SCRIPT" ]; then
            ts "Running '$SCRIPT'"
            "$SCRIPT"
        fi
    else
        MSG="Already at '$NEW_LOCATION'"
        ts $MSG
        osascript -e "display notification \"$MSG\" with title \"Location switcher\" sound name \"Blow\""
    fi
fi
