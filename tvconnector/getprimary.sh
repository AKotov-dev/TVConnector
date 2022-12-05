#!/bin/bash

#Список активных дисплеев, Primary всегда сверху (0:)
xrandr --listactivemonitors | grep -E "0:|1:" | awk '{ print $4 }' > ~/.config/tvconnector/disp

#Имя Primary (или 0:) дисплея
primary=$(cat ~/.config/tvconnector/disp | head -n1)

#Получаем список разрешений Primary дисплея
xrandr | awk -v monitor="^$primary connected" '/disconnected/ {p = 0} $0 ~ monitor {p = 1} p' | \
grep "\*" | awk '{ print $1 }' > ~/.config/tvconnector/list0
