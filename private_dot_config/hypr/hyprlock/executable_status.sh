#!/usr/bin/env bash

# Battery
battery_str=""
for battery in /sys/class/power_supply/*BAT*; do
  if [[ -f "$battery/uevent" ]]; then
    cap=$(cat "$battery/capacity" 2>/dev/null || echo "")
    stat=$(cat "$battery/status" 2>/dev/null || echo "")
    if [[ -n "$cap" ]]; then
      if [[ "$stat" == "Charging" ]]; then
        battery_str=" $cap%"
      else
        if [ "$cap" -le 20 ]; then
          battery_str="  $cap%"
        elif [ "$cap" -le 40 ]; then
          battery_str="  $cap%"
        elif [ "$cap" -le 60 ]; then
          battery_str="  $cap%"
        elif [ "$cap" -le 80 ]; then
          battery_str="  $cap%"
        else
          battery_str="  $cap%"
        fi
      fi
    fi
    break
  fi
done

# WiFi
wifi_str=""
wifi_info=$(nmcli -t -f active,ssid,signal dev wifi 2>/dev/null | grep '^yes:' | head -1)
if [ -n "$wifi_info" ]; then
    ssid=$(echo "$wifi_info" | cut -d: -f2)
    sig=$(echo "$wifi_info" | cut -d: -f3)
    wifi_str="  $ssid ($sig%)"
else
    eth=$(nmcli -t -f type,state dev 2>/dev/null | grep '^ethernet:connected')
    if [ -n "$eth" ]; then
        wifi_str="󰈀 Ethernet"
    else
        wifi_str="󰖪 Offline"
    fi
fi

if [ -n "$battery_str" ] && [ -n "$wifi_str" ]; then
    echo "$battery_str   $wifi_str"
elif [ -n "$battery_str" ]; then
    echo "$battery_str"
else
    echo "$wifi_str"
fi
