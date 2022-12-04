#!/bin/bash

#Список активных дисплеев, Primary всегда сверху (0:)
xrandr --listactivemonitors | grep -E "0:|1:" | cut -f6 -d" " > ~/.config/tvconnector/disp

#Имя Primary дисплея
primary=$(cat ~/.config/tvconnector/disp | head -n1)

#Получаем список разрешений Primary дисплея
xrandr | awk -v monitor="^$primary connected" '/disconnected/ {p = 0} $0 ~ monitor {p = 1} p' | \
tail -n+2 | sed 's/^[[:blank:]]*//g' > ~/.config/tvconnector/list0
