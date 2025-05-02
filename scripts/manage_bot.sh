#!/bin/bash

# Включаем строгий режим
set -euo pipefail

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m' # No Color

# Файлы логов
BOT_LOG_FILE="/opt/support-bot/logs/bot.log"
ERROR_LOG_FILE="/opt/support-bot/logs/error.log"

# Функция для логирования
log() {
    local level=$1
    local message=$2
    echo -e "${!level}${message}${NC}"
}

# Функция для запуска docker-compose
docker_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# Функция для управления .env файлом
manage_env_file() {
    local env_file=".env"
    local env_example=".env.example"
    local created=false

    log "BLUE" "📝 Управление конфигурацией .env..."

    # Выводим текущую директорию
    log "BLUE" "📍 Текущая директория: $(pwd)"

    # Проверяем существование файлов
    if [ ! -f "$env_file" ]; then
        if [ -f "$env_example" ]; then
            cp "$env_example" "$env_file"
            created=true
            log "GREEN" "✅ Создан новый .env файл из примера"
        else
            log "YELLOW" "⚠️ Файл .env.example не найден, создаем базовый .env"
            cat > "$env_file" << EOL
# Конфигурация бота
BOT_TOKEN=123456789:AAGASD2cxfatkDasDE22dqfawdfawd2WD-UI
BOT_DEV_ID=123456789
BOT_GROUP_ID=-100123456789
BOT_EMOJI_ID=5417915203100613993
BOT_NAME=support-bot

REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
EOL
            created=true
            log "YELLOW" "⚠️ Создан базовый .env файл"
        fi
    fi

    # Предлагаем отредактировать файл
    read -r -p "Редактировать .env файл сейчас? [Y/n] " response
    response=${response:-Y}
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        # Добавляем логирование
        if command -v nano &> /dev/null; then
            log "BLUE" "🚀 Запускаем nano..."
            nano "$env_file"
            editor_result=$?
        else
            log "BLUE" "🚀 Запускаем vi..."
            vi "$env_file"
            editor_result=$?
        fi

        # Проверяем код возврата редактора
        if [ "$editor_result" -ne 0 ]; then
            log "RED" "❌ Редактор вернул код ошибки: $editor_result"
            log "YELLOW" "⚠️ Файл .env необходимо настроить для работы бота."
            return 1
        fi
    else
        log "YELLOW" "⚠️ Файл .env необходимо настроить для работы бота."
        return 1
    fi

    log "GREEN" "✅ Конфигурация .env завершена"
    return 0
}

# Функция для обновления репозитория
update_repo() {
    log "BLUE" "🔄 Обновление репозитория..."

    # Инициализация переменной STASHED
    STASHED="false"

    # Stash local changes to .env
    if git diff --quiet HEAD -- .env; then
        log "BLUE" "No local changes to .env"
    else
        log "BLUE" "Stashing local changes to .env"
        git stash push -u .env
        STASHED="true"
    fi

    git fetch
    git reset --hard origin/main
    log "GREEN" "✅ Репозиторий обновлен"

     # Restore stashed changes to .env
    if [[ "$STASHED" == "true" ]]; then
        log "BLUE" "Restoring stashed changes to .env"
        git stash pop
    fi
    log "GREEN" "✅ Репозиторий обновлен"
}

# Функция для управления контейнером
manage_container() {
    local action=$1

    log "BLUE" "🐳 Управление контейнером..."

    # Загружаем переменные окружения из файла .env
    if [ -f ".env" ]; then
        log "BLUE" "🔑 Загружаем переменные окружения из .env"
        # Явно указываем кодировку UTF-8 при загрузке .env
        export $(grep -v '^#' .env | xargs -0)
    else
        log "RED" "❌ Файл .env не найден. Создайте его и настройте переменные окружения."
        return 1
    fi

    # Проверяем, установлена ли переменная BOT_NAME
    if [ -z "$BOT_NAME" ]; then
        log "RED" "❌ Переменная BOT_NAME не установлена. Установите ее в файле .env"
        return 1
    fi

    # Выводим значение переменной BOT_NAME
    log "BLUE" "🔍 BOT_NAME: $BOT_NAME"

    export DOCKER_UID DOCKER_GID
    export CREATED_BY="$CURRENT_USER"
    export CREATED_AT="$CURRENT_TIME"

    case $action in
        "restart")
            log "BLUE" "🔄 Перезапуск контейнера..."
            docker_compose_cmd -f docker/docker-compose.yml down --remove-orphans || force_remove_container
            docker_compose_cmd -f docker/docker-compose.yml up -d
            ;;
        "stop")
            log "BLUE" "⏹️ Остановка контейнера..."
            docker_compose_cmd -f docker/docker-compose.yml down --remove-orphans || force_remove_container
            ;;
        "start")
            log "BLUE" "▶️ Запуск контейнера..."
            if docker ps -a | grep -q "$BOT_NAME"; then
                force_remove_container
            fi
            docker_compose_cmd -f docker/docker-compose.yml up -d
            ;;
    esac

    if [ "$action" = "start" ] || [ "$action" = "restart" ]; then
        log "BLUE" "⏳ Ожидание запуска бота..."
        sleep 5

        if ! docker ps | grep -q "$BOT_NAME"; then
            log "RED" "❌ Ошибка запуска контейнера"
            docker_compose_cmd -f docker/docker-compose.yml logs
            return 1
        fi

        log "GREEN" "✅ Контейнер запущен"
        docker_compose_cmd -f docker/docker-compose.yml logs --tail=10
    fi
}

# Функция для принудительного удаления контейнера
force_remove_container() {
    if docker ps -a | grep -q "$BOT_NAME"; then
        log "YELLOW" "⚠️ Принудительное удаление контейнера..."
        docker stop "$BOT_NAME"
        docker rm "$BOT_NAME"
    fi
}

# Функция для очистки временных файлов
cleanup() {
    log "BLUE" "🧹 Очистка временных файлов..."
    rm -rf /tmp/tmp.*
}

# Функция для очистки Docker
cleanup_docker() {
    log "BLUE" "🧹 Очистка Docker..."
    docker system prune -af --volumes
    log "GREEN" "✅ Docker очищен"
}

# Получаем текущую дату и время в формате YYYY-MM-DD HH:MM:SS (UTC)
CURRENT_TIME=$(date -u +%Y-%m-%d\ %H:%M:%S)

# Получаем логин текущего пользователя
CURRENT_USER=$(whoami)

# Основное меню
main_menu() {
    while true; do
        log "YELLOW" "🤖 Telegram Support Bot"
        log "YELLOW" "========================"
        log "GREEN" "1. ⬆️ Обновить из репозитория"
        log "GREEN" "2. 📝 Создать или редактировать .env файл"
        log "GREEN" "3. 🚀 Собрать и запустить контейнер бота"
        log "GREEN" "4. ⏹️ Остановить и удалить контейнер бота"
        log "GREEN" "5. 📊 Показать логи (все)"
        log "GREEN" "6. ❌ Показать логи ошибок"
        log "GREEN" "7. 🔄 Перезапустить бота"
        log "GREEN" "8. 🧹 Очистить старые логи и бэкапы"
        log "GREEN" "0. 🚪 Выйти"

        read -r -p "Выберите действие (0-8): " choice

        case "$choice" in
            1)
                update_repo
                ;;
            2)
                manage_env_file
                ;;
            3)
                manage_container "start"
                ;;
            4)
                manage_container "stop"
                force_remove_container
                cleanup_docker # Добавляем очистку Docker
                ;;
            5)
                # Показать логи (все)
                log "MAGENTA" "📊 Показываем все логи бота..."
                if [ -f "$BOT_LOG_FILE" ]; then
                    cat "$BOT_LOG_FILE"
                else
                    log "RED" "❌ Файл логов не найден: $BOT_LOG_FILE"
                fi
                ;;
            6)
                # Показать логи ошибок
                log "RED" "❌ Показываем логи ошибок бота..."
                if [ -f "$ERROR_LOG_FILE" ]; then
                    cat "$ERROR_LOG_FILE"
                else
                    log "RED" "❌ Файл логов ошибок не найден: $ERROR_LOG_FILE"
                fi
                ;;
            7)
                manage_container "restart"
                ;;
            8)
                # TODO: Implement cleanup old logs and backups
                log "YELLOW" "⚠️ Функция очистки старых логов и бэкапов еще не реализована."
                ;;
            0)
                log "BLUE" "🚪 Выход..."
                break
                ;;
            *)
                log "RED" "❌ Неверный выбор. Пожалуйста, выберите действие от 0 до 8."
                ;;
        esac
    done
}

# Запускаем основное меню
main_menu

# Очистка временных файлов перед выходом
cleanup