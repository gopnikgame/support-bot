#!/bin/bash

# Определяем корневой каталог проекта
ROOT_DIR="$(dirname "$(dirname "$(readlink -f "$0")")")"
cd "$ROOT_DIR" || { echo "Ошибка перехода в директорию проекта"; exit 1; }

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
LOGS_DIR="$ROOT_DIR/logs"
mkdir -p "$LOGS_DIR"
BOT_LOG_FILE="$LOGS_DIR/bot.log"
ERROR_LOG_FILE="$LOGS_DIR/error.log"

# Получаем текущую дату и время в формате YYYY-MM-DD HH:MM:SS (UTC)
CURRENT_TIME=$(date -u +%Y-%m-%d\ %H:%M:%S)

# Получаем логин текущего пользователя
CURRENT_USER=$(whoami)

# Инициализация переменных Docker
DOCKER_UID=$(id -u)
DOCKER_GID=$(id -g)

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
    local env_file="$ROOT_DIR/.env"
    local env_example="$ROOT_DIR/.env.example"
    local created=false

    log "BLUE" "📝 Управление конфигурацией .env..."

    # Выводим текущую директорию
    log "BLUE" "📍 Корневая директория проекта: $ROOT_DIR"

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
BOT_TOKEN=your_bot_token_here
BOT_DEV_ID=your_dev_id_here
BOT_GROUP_ID=your_group_id_here
BOT_EMOJI_ID=5417915203100613993
BOT_NAME=support-bot

REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
EOL
            created=true
            log "YELLOW" "⚠️ Создан базовый .env файл. Пожалуйста, обновите токен бота и другие данные!"
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
    if ! git diff --quiet HEAD -- .env 2>/dev/null; then
        log "BLUE" "Сохранение локальных изменений в .env"
        git stash push -m "Автоматическое сохранение .env перед обновлением" -- .env
        STASHED="true"
    else
        log "BLUE" "Нет изменений в .env для сохранения"
    fi

    git fetch
    git reset --hard origin/main
    log "GREEN" "✅ Репозиторий обновлен"

    # Restore stashed changes to .env
    if [[ "$STASHED" == "true" ]]; then
        log "BLUE" "Восстановление локальных изменений .env"
        git stash pop
        if [ $? -ne 0 ]; then
            log "YELLOW" "⚠️ Возникли конфликты при восстановлении .env. Проверьте файл вручную."
        fi
    fi
}

# Функция для управления контейнером
manage_container() {
    local action=$1

    log "BLUE" "🐳 Управление контейнером..."

    # Загружаем переменные окружения из файла .env
    if [ -f "$ROOT_DIR/.env" ]; then
        log "BLUE" "🔑 Загружаем переменные окружения из .env"
        # Исправление: убираем параметр -0 для xargs
        export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)
    else
        log "RED" "❌ Файл .env не найден. Создайте его и настройте переменные окружения."
        return 1
    fi

    # Проверяем, установлена ли переменная BOT_NAME
    if [ -z "${BOT_NAME:-}" ]; then
        log "RED" "❌ Переменная BOT_NAME не установлена. Установите ее в файле .env"
        return 1
    fi

    # Выводим значение переменной BOT_NAME
    log "BLUE" "🔍 BOT_NAME: $BOT_NAME"

    # Экспортируем переменные для docker-compose
    export DOCKER_UID DOCKER_GID
    export CREATED_BY="$CURRENT_USER"
    export CREATED_AT="$CURRENT_TIME"

    # Путь к docker-compose файлу
    local compose_file="$ROOT_DIR/docker-compose.yml"

    # Проверяем наличие docker-compose файла
    if [ ! -f "$compose_file" ]; then
        log "RED" "❌ Файл docker-compose.yml не найден в: $compose_file"
        return 1
    fi

    case $action in
        "restart")
            log "BLUE" "🔄 Перезапуск контейнера..."
            docker_compose_cmd -f "$compose_file" down --remove-orphans || force_remove_container
            docker_compose_cmd -f "$compose_file" up -d
            ;;
        "stop")
            log "BLUE" "⏹️ Остановка контейнера..."
            docker_compose_cmd -f "$compose_file" down --remove-orphans || force_remove_container
            ;;
        "start")
            log "BLUE" "▶️ Запуск контейнера..."
            if [ -n "${BOT_NAME:-}" ] && docker ps -a | grep -q "$BOT_NAME"; then
                force_remove_container
            fi
            docker_compose_cmd -f "$compose_file" up -d
            ;;
    esac

    if [ "$action" = "start" ] || [ "$action" = "restart" ]; then
        log "BLUE" "⏳ Ожидание запуска бота..."
        sleep 5

        if [ -n "${BOT_NAME:-}" ] && ! docker ps | grep -q "$BOT_NAME"; then
            log "RED" "❌ Ошибка запуска контейнера"
            docker_compose_cmd -f "$compose_file" logs
            return 1
        fi

        log "GREEN" "✅ Контейнер запущен"
        docker_compose_cmd -f "$compose_file" logs --tail=10
    fi
}

# Функция для принудительного удаления контейнера
force_remove_container() {
    if [ -z "${BOT_NAME:-}" ]; then
        log "RED" "❌ Переменная BOT_NAME не установлена. Невозможно удалить контейнер."
        return 1
    fi

    if docker ps -a | grep -q "$BOT_NAME"; then
        log "YELLOW" "⚠️ Принудительное удаление контейнера..."
        docker stop "$BOT_NAME" || true
        docker rm "$BOT_NAME" || true
    fi
}

# Функция для очистки временных файлов
cleanup() {
    log "BLUE" "🧹 Очистка временных файлов..."
    # Используем более безопасный способ
    find /tmp -maxdepth 1 -type d -name "tmp.*" -user "$CURRENT_USER" -exec rm -rf {} \; 2>/dev/null || true
}

# Функция для очистки Docker
cleanup_docker() {
    log "BLUE" "🧹 Очистка Docker..."
    docker system prune -f
    log "GREEN" "✅ Docker очищен (удалены неиспользуемые образы, контейнеры и сети)"

    read -r -p "Очистить также все тома Docker? [y/N] " response
    response=${response:-N}
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        docker system prune -af --volumes
        log "GREEN" "✅ Docker очищен полностью (включая тома)"
    fi
}

# Функция для очистки логов бота
cleanup_logs() {
    log "BLUE" "🧹 Очистка старых логов..."
    
    # Проверяем существование директории логов
    if [ -d "$LOGS_DIR" ]; then
        # Создаем архив с текущей датой
        local backup_date=$(date +%Y%m%d-%H%M%S)
        local backup_dir="$ROOT_DIR/logs_backup"
        mkdir -p "$backup_dir"
        
        # Архивируем логи перед удалением
        if tar -czf "$backup_dir/logs_$backup_date.tar.gz" -C "$ROOT_DIR" logs 2>/dev/null; then
            log "GREEN" "✅ Создан архив логов: logs_$backup_date.tar.gz"
            
            # Очищаем текущие логи
            echo "" > "$BOT_LOG_FILE"
            echo "" > "$ERROR_LOG_FILE"
            log "GREEN" "✅ Логи очищены"
            
            # Удаляем старые архивы (старше 30 дней)
            find "$backup_dir" -name "logs_*.tar.gz" -type f -mtime +30 -delete
            log "GREEN" "✅ Старые архивы логов удалены"
        else
            log "RED" "❌ Ошибка при создании архива логов"
        fi
    else
        log "YELLOW" "⚠️ Директория логов не найдена"
        mkdir -p "$LOGS_DIR"
        touch "$BOT_LOG_FILE" "$ERROR_LOG_FILE"
        log "GREEN" "✅ Созданы пустые файлы логов"
    fi
}

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
                cleanup_docker
                ;;
            5)
                # Показать логи (все)
                log "MAGENTA" "📊 Показываем все логи бота..."
                if [ -f "$BOT_LOG_FILE" ]; then
                    less "$BOT_LOG_FILE" || cat "$BOT_LOG_FILE"
                else
                    log "RED" "❌ Файл логов не найден: $BOT_LOG_FILE"
                fi
                ;;
            6)
                # Показать логи ошибок
                log "RED" "❌ Показываем логи ошибок бота..."
                if [ -f "$ERROR_LOG_FILE" ]; then
                    less "$ERROR_LOG_FILE" || cat "$ERROR_LOG_FILE"
                else
                    log "RED" "❌ Файл логов ошибок не найден: $ERROR_LOG_FILE"
                fi
                ;;
            7)
                manage_container "restart"
                ;;
            8)
                # Реализация очистки логов и бэкапов
                cleanup_logs
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
