#!/bin/bash
SPEED=$1
USER_NAME="rom"

XAUTH_FILE=""

# 1. Пробуем взять из переменной окружения
if [ -n "$XAUTHORITY" ] && [ -f "$XAUTHORITY" ]; then
    XAUTH_FILE="$XAUTHORITY"
fi

# 2. Ищем динамический файл в /tmp, принадлежащий пользователю
if [ -z "$XAUTH_FILE" ]; then
    XAUTH_FILE=$(find /tmp -maxdepth 1 -name "xauth*" -user "$USER_NAME" -type f 2>/dev/null | head -n 1)
fi

# 3. Запасной вариант
if [ -z "$XAUTH_FILE" ]; then
    XAUTH_FILE="/home/$USER_NAME/.Xauthority"
fi

export DISPLAY=:0
export XAUTHORITY="$XAUTH_FILE"

# Убрали sudo отсюда, так как скрипт уже запущен через sudo из виджета
if [ "$SPEED" == "auto" ]; then
    env DISPLAY=:0 XAUTHORITY="$XAUTHORITY" nvidia-settings -a gpu:0/GPUFanControlState=0
else
    env DISPLAY=:0 XAUTHORITY="$XAUTHORITY" nvidia-settings -a fan:0/GPUTargetFanSpeed=$SPEED
fi
