#!/bin/bash

echo "🚀 Начало установки виджета NVIDIA Fan Control..."

# 1. Создаем директорию для пользовательских скриптов, если её нет
mkdir -p ~/.local/bin

# 2. Копируем скрипт управления и даем права на выполнение
echo "📦 Установка вспомогательного скрипта..."
cp contents/code/nvidia-fan.sh ~/.local/bin/nvidia-fan.sh
chmod +x ~/.local/bin/nvidia-fan.sh

# 3. Упаковываем виджет в .plasmoid
echo "📦 Упаковка виджета..."
zip -r nvidia-fan-control.plasmoid metadata.json contents/ > /dev/null

# 4. Устанавливаем виджет в Plasma
echo "⚙️ Установка виджета в систему..."
plasmapkg2 -i nvidia-fan-control.plasmoid

echo "✅ Установка успешно завершена!"
echo "💡 Совет: Чтобы скрипт работал без запроса пароля, добавьте в sudoers:"
echo "   $USER ALL=(ALL) NOPASSWD: /home/$USER/.local/bin/nvidia-fan.sh"
echo "🔄 Перезапустите Plasma (или выйдите и войдите), чтобы увидеть виджет."
