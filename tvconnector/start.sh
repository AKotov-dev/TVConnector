#!/bin/bash

clear

#Список активных дисплеев (развернутый)
xrandr -q | grep "[A-Z]" | grep -iEv "disconnected|screen" > ~/.config/tvconnector/disp

#Поместить PRIMARY сверху и создать disp_tmp
cat <(grep 'primary' ~/.config/tvconnector/disp) <(grep -v 'primary' ~/.config/tvconnector/disp) | cut -f1 -d" " \
> ~/.config/tvconnector/disp_tmp

#Создать сортированный disp (primary сверху для list0)
mv -f ~/.config/tvconnector/disp_tmp ~/.config/tvconnector/disp

#Индекс списков
primary=$(cat ~/.config/tvconnector/disp | head -n1)

#Получаем список разрешений primary дисплея
xrandr | awk -v monitor="^$primary connected" '/disconnected/ {p = 0} $0 ~ monitor {p = 1} p' | \
tail -n+2 | sed 's/^[[:blank:]]*//g' > ~/.config/tvconnector/list0


