#!/bin/bash

# Включаем строгий режим
set -euo pipefail

# Аргумент для имени экземпляра (по умолчанию - пустая строка)
INSTANCE_NAME="${1:-}"

# Конфигурация
REPO_URL="https://github.com/gopnikgame/support-bot.git"
PROJECT_DIR="support-bot"

# Если указано имя экземпляра, добавляем суффикс к PROJECT_DIR
if [ -n "$INSTANCE_NAME" ]; then
    PROJECT_DIR="${PROJECT_DIR}_${INSTANCE_NAME}"
fi

INSTALL_DIR="/opt/$PROJECT_DIR" # Постоянная директория для установки
LOG_DIR="/var/log"
LOG_FILE="$LOG_DIR/$PROJECT_DIR.log"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для логирования
log() {
    local level=$1
    local message=$2
    # Создаем директорию для логов если её нет
    sudo mkdir -p "$LOG_DIR"
    echo -e "${!level}${message}${NC}" | tee -a "$LOG_FILE"
}

# Проверка прав суперпользователя
check_sudo() {
    if [ "$EUID" -ne 0 ]; then
        if ! sudo -n true 2>/dev/null; then
            log "YELLOW" "⚠️ Для выполнения некоторых операций требуются права суперпользователя"
            log "YELLOW" "⚠️ Пожалуйста, введите пароль при запросе"
        fi
    fi
}

# Проверка операционной системы
check_os() {
    if [ ! -f /etc/os-release ]; then
        log "RED" "❌ Не удалось определить операционную систему"
        log "YELLOW" "⚠️ Этот скрипт предназначен для Ubuntu/Debian"
        exit 1
    fi
    
    . /etc/os-release
    if [[ "$ID" != "ubuntu" ]] && [[ "$ID" != "debian" ]]; then
        log "YELLOW" "⚠️ Обнаружена ОС: $PRETTY_NAME"
        log "YELLOW" "⚠️ Этот скрипт оптимизирован для Ubuntu/Debian"
        read -r -p "Продолжить? [y/N] " response
        response=${response:-N}
        if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            log "BLUE" "Установка отменена"
            exit 0
        fi
    fi
}

# Проверка зависимостей
check_dependencies() {
    log "BLUE" "🔍 Проверка зависимостей..."
    local missing_deps=()
    
    # Проверяем git
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    # Проверяем nano
    if ! command -v nano &> /dev/null; then
        missing_deps+=("nano")
    fi
    
    # Проверяем curl (необходим для установки Docker)
    if ! command -v curl &> /dev/null; then
        missing_deps+=("curl")
    fi
    
    # Проверяем gnupg (необходим для установки Docker)
    if ! command -v gpg &> /dev/null; then
        missing_deps+=("gnupg")
    fi
    
    # Устанавливаем недостающие зависимости
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "YELLOW" "⚠️ Установка необходимых пакетов: ${missing_deps[*]}..."
        sudo apt-get update || {
            log "RED" "❌ Ошибка обновления списка пакетов"
            exit 1
        }
        sudo apt-get install -y "${missing_deps[@]}" || {
            log "RED" "❌ Ошибка установки зависимостей"
            exit 1
        }
        log "GREEN" "✅ Зависимости установлены"
    else
        log "GREEN" "✅ Все необходимые зависимости установлены"
    fi
}

# Основная функция установки
main() {
    log "BLUE" "🚀 Запуск установщика Support Bot..."
    
    # Проверяем ОС
    check_os
    
    # Проверяем права
    check_sudo
    
    # Проверяем и устанавливаем зависимости
    check_dependencies
    
    # Проверка существования директории установки
    if [ -d "$INSTALL_DIR" ]; then
        log "BLUE" "🚀 Директория установки существует: $INSTALL_DIR"
        
        # Переходим в директорию установки
        cd "$INSTALL_DIR" || {
            log "RED" "❌ Ошибка перехода в директорию $INSTALL_DIR"
            exit 1
        }
        
        # Добавляем права на выполнение скрипта manage_bot.sh
        if [ -f "manage_bot.sh" ]; then
            chmod +x manage_bot.sh
            log "BLUE" "🚀 Запуск основного скрипта установки для экземпляра $PROJECT_DIR..."
            ./manage_bot.sh "$INSTANCE_NAME"
        else
            log "RED" "❌ Файл manage_bot.sh не найден в $INSTALL_DIR"
            log "YELLOW" "⚠️ Попытка переустановки..."
            sudo rm -rf "$INSTALL_DIR"
            main
        fi
    else
        log "BLUE" "⬇️ Клонирование репозитория для экземпляра $PROJECT_DIR..."
        
        # Создаем временную директорию
        TEMP_DIR=$(mktemp -d) || {
            log "RED" "❌ Ошибка создания временной директории"
            exit 1
        }
        
        # Переходим во временную директорию
        cd "$TEMP_DIR" || {
            log "RED" "❌ Ошибка перехода во временную директорию"
            exit 1
        }
        
        # Клонируем репозиторий
        log "BLUE" "📦 Клонирование репозитория..."
        if ! git clone "$REPO_URL" "$PROJECT_DIR"; then
            log "RED" "❌ Ошибка клонирования репозитория"
            rm -rf "$TEMP_DIR"
            exit 1
        fi
        
        # Переходим в директорию проекта
        cd "$PROJECT_DIR" || {
            log "RED" "❌ Ошибка перехода в директорию проекта"
            rm -rf "$TEMP_DIR"
            exit 1
        }
        
        # Создаем директорию установки, если она не существует
        sudo mkdir -p "$INSTALL_DIR" || {
            log "RED" "❌ Ошибка создания директории установки"
            rm -rf "$TEMP_DIR"
            exit 1
        }
        
        # Копируем файлы в директорию установки
        log "BLUE" "📦 Копирование файлов в директорию установки..."
        sudo cp -r . "$INSTALL_DIR" || {
            log "RED" "❌ Ошибка копирования файлов"
            rm -rf "$TEMP_DIR"
            exit 1
        }
        
        # Устанавливаем права владельца
        sudo chown -R "$USER:$USER" "$INSTALL_DIR" || {
            log "YELLOW" "⚠️ Не удалось установить права владельца"
        }
        
        # Переходим в директорию установки
        cd "$INSTALL_DIR" || {
            log "RED" "❌ Ошибка перехода в директорию установки"
            rm -rf "$TEMP_DIR"
            exit 1
        }
        
        # Добавляем права на выполнение скрипта manage_bot.sh
        chmod +x manage_bot.sh || {
            log "RED" "❌ Ошибка установки прав на выполнение"
            rm -rf "$TEMP_DIR"
            exit 1
        }
        
        # Запускаем скрипт manage_bot.sh с именем экземпляра
        log "BLUE" "🚀 Запуск основного скрипта установки..."
        ./manage_bot.sh "$INSTANCE_NAME"
        
        # Удаляем временную директорию
        rm -rf "$TEMP_DIR"
    fi
    
    log "GREEN" "✅ Установка/обновление экземпляра $PROJECT_DIR завершено"
}

# Запускаем основную функцию
main