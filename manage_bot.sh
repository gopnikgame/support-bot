#!/bin/bash

# Аргумент для имени экземпляра (по умолчанию - пустая строка)
INSTANCE_NAME="${1:-}"

# Определяем корневой каталог проекта (теперь скрипт находится в корне)
ROOT_DIR="$(dirname "$(readlink -f "$0")")"
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

# Название бота для контейнера и префикса
DEFAULT_BOT_NAME="support-bot"
if [ -n "$INSTANCE_NAME" ]; then
    BOT_NAME="${DEFAULT_BOT_NAME}_${INSTANCE_NAME}"
else
    BOT_NAME="${DEFAULT_BOT_NAME}"
fi

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

# Функция для проверки и коррекции установки Docker
check_fix_docker() {
    log "BLUE" "🔍 Проверка установки Docker..."
    
    # Проверяем, установлен ли Docker через snap
    if command -v snap &> /dev/null && snap list 2>/dev/null | grep -q docker; then
        log "YELLOW" "⚠️ Обнаружен Docker, установленный через snap. Рекомендуется удалить его и установить официальную версию."
        
        read -r -p "Удалить Docker (snap) и установить официальную версию? [Y/n] " response
        response=${response:-Y}
        
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            log "BLUE" "🔄 Удаление Docker, установленного через snap..."
            
            # Останавливаем все контейнеры перед удалением Docker
            log "YELLOW" "⚠️ Останавливаем все запущенные контейнеры..."
            docker ps -q | xargs -r docker stop || true
            
            # Удаляем Docker через snap
            sudo snap remove docker || {
                log "RED" "❌ Не удалось удалить Docker через snap"
                return 1
            }
            
            log "GREEN" "✅ Docker (snap) удален"
            
            # Установка официальной версии Docker
            log "BLUE" "⬇️ Установка официальной версии Docker..."
            
            # Обновляем информацию о пакетах
            sudo apt-get update
            
            # Устанавливаем необходимые пакеты для добавления репозитория
            sudo apt-get install -y ca-certificates curl gnupg || {
                log "RED" "❌ Ошибка при установке необходимых пакетов"
                return 1
            }
            
            # Создаем директорию для ключей
            sudo install -m 0755 -d /etc/apt/keyrings
            
            # Скачиваем официальный ключ Docker и добавляем его в keyring
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            sudo chmod a+r /etc/apt/keyrings/docker.gpg
            
            # Добавляем репозиторий Docker
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
                sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # Обновляем информацию о пакетах после добавления репозитория
            sudo apt-get update
            
            # Устанавливаем Docker Engine, containerd и Docker Compose
            sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose || {
                log "RED" "❌ Ошибка при установке Docker"
                return 1
            }
            
            # Добавляем текущего пользователя в группу docker
            sudo usermod -aG docker "$CURRENT_USER"
            
            log "GREEN" "✅ Docker успешно установлен"
            log "YELLOW" "⚠️ Для применения изменений в группах пользователей может потребоваться перезайти в систему"
            
            # Проверяем установку
            if command -v docker &> /dev/null; then
                docker --version
                docker-compose --version
                log "GREEN" "✅ Docker и Docker Compose установлены и готовы к использованию"
            else
                log "RED" "❌ Возникла проблема с установкой Docker"
                return 1
            fi
            
            # Спрашиваем пользователя, хочет ли он перезайти в систему
            read -r -p "Изменения в группах требуют перезахода в систему. Выйти сейчас? [y/N] " response
            response=${response:-N}
            
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                log "YELLOW" "⚠️ Выход из системы. После повторного входа запустите скрипт снова."
                exit 0
            fi
        else
            log "YELLOW" "⚠️ Продолжение работы с Docker, установленным через snap. Возможны ограничения."
        fi
    else
        # Проверяем наличие Docker
        if ! command -v docker &> /dev/null; then
            log "YELLOW" "⚠️ Docker не установлен. Необходимо установить Docker для работы бота."
            
            read -r -p "Установить официальную версию Docker? [Y/n] " response
            response=${response:-Y}
            
            if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                log "BLUE" "⬇️ Установка официальной версии Docker..."
                
                # Обновляем информацию о пакетах
                sudo apt-get update
                
                # Устанавливаем необходимые пакеты для добавления репозитория
                sudo apt-get install -y ca-certificates curl gnupg || {
                    log "RED" "❌ Ошибка при установке необходимых пакетов"
                    return 1
                }
                
                # Создаем директорию для ключей
                sudo install -m 0755 -d /etc/apt/keyrings
                
                # Скачиваем официальный ключ Docker и добавляем его в keyring
                curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                sudo chmod a+r /etc/apt/keyrings/docker.gpg
                
                # Определяем дистрибутив для репозитория
                DIST=$(lsb_release -cs)
                
                # Добавляем репозиторий Docker
                echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $DIST stable" | \
                    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                
                # Обновляем информацию о пакетах после добавления репозитория
                sudo apt-get update
                
                # Устанавливаем Docker Engine, containerd и Docker Compose
                sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose || {
                    log "RED" "❌ Ошибка при установке Docker"
                    return 1
                }
                
                # Добавляем текущего пользователя в группу docker
                sudo usermod -aG docker "$CURRENT_USER"
                
                log "GREEN" "✅ Docker успешно установлен"
                log "YELLOW" "⚠️ Для применения изменений в группах пользователей может потребоваться перезайти в систему"
                
                # Проверяем установку
                if command -v docker &> /dev/null; then
                    docker --version
                    docker-compose --version
                    log "GREEN" "✅ Docker и Docker Compose установлены и готовы к использованию"
                else
                    log "RED" "❌ Возникла проблема с установкой Docker"
                    return 1
                fi
                
                # Спрашиваем пользователя, хочет ли он перезайти в систему
                read -r -p "Изменения в группах требуют перезахода в систему. Выйти сейчас? [y/N] " response
                response=${response:-N}
                
                if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                    log "YELLOW" "⚠️ Выход из системы. После повторного входа запустите скрипт снова."
                    exit 0
                fi
            else
                log "RED" "❌ Docker требуется для работы бота. Установка отменена."
                return 1
            fi
        else
            log "GREEN" "✅ Обнаружена стандартная установка Docker"
            docker --version
            
            # Проверяем Docker Compose
            if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
                log "YELLOW" "⚠️ Docker Compose не установлен"
                
                read -r -p "Установить Docker Compose? [Y/n] " response
                response=${response:-Y}
                
                if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
                    log "BLUE" "⬇️ Установка Docker Compose..."
                    sudo apt-get update
                    sudo apt-get install -y docker-compose || {
                        log "RED" "❌ Ошибка при установке Docker Compose"
                        return 1
                    }
                    log "GREEN" "✅ Docker Compose успешно установлен"
                    docker-compose --version
                fi
            else
                log "GREEN" "✅ Docker Compose установлен"
                if command -v docker-compose &> /dev/null; then
                    docker-compose --version
                else
                    docker compose version
                fi
            fi
        fi
    fi
    
    return 0
}

# Функция для запуска docker-compose
docker_compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose "$@"
    else
        log "RED" "❌ Не найден docker-compose или docker compose"
        return 1
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
            
            # Автоматически обновляем BOT_NAME в .env файле
            sed -i "s/BOT_NAME=support-bot/BOT_NAME=$BOT_NAME/" "$env_file"
            log "GREEN" "✅ BOT_NAME обновлен на $BOT_NAME в файле .env"
        else
            log "YELLOW" "⚠️ Файл .env.example не найден, создаем базовый .env"
            cat > "$env_file" << EOL
# Конфигурация бота
BOT_TOKEN=your_bot_token_here
BOT_DEV_ID=your_dev_id_here
BOT_GROUP_ID=your_group_id_here
BOT_EMOJI_ID=5417915203100613993
BOT_NAME=$BOT_NAME

REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
EOL
            created=true
            log "YELLOW" "⚠️ Создан базовый .env файл. Пожалуйста, обновите токен бота и другие данные!"
        fi
    else
        # Проверяем, соответствует ли BOT_NAME в .env файле текущему имени экземпляра
        if ! grep -q "BOT_NAME=$BOT_NAME" "$env_file"; then
            log "YELLOW" "⚠️ Обновляем BOT_NAME в .env файле..."
            sed -i "s/BOT_NAME=.*/BOT_NAME=$BOT_NAME/" "$env_file"
            log "GREEN" "✅ BOT_NAME обновлен на $BOT_NAME"
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
    
    # Проверяем и исправляем установку Docker
    check_fix_docker || {
        log "RED" "❌ Необходимо исправить установку Docker для продолжения."
        return 1
    }
    
    # Выводим текущую директорию для отладки
    log "BLUE" "📍 Текущая директория: $(pwd)"
    log "BLUE" "🔍 Проверка наличия docker-compose.yml: $(ls -la | grep docker-compose.yml || echo 'Файл не найден')"

    # Загружаем переменные окружения из файла .env
    if [ -f ".env" ]; then
        log "BLUE" "🔑 Загружаем переменные окружения из .env"
        # Без полного пути - работаем с файлом в текущей директории
        export $(grep -v '^#' .env | xargs)
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

    # Проверяем наличие docker-compose файла (в текущей директории)
    if [ ! -f "docker-compose.yml" ]; then
        log "RED" "❌ Файл docker-compose.yml не найден в текущей директории!"
        log "BLUE" "🔍 Содержимое директории:"
        ls -la
        return 1
    fi

    case $action in
        "restart")
            log "BLUE" "🔄 Перезапуск контейнера..."
            docker_compose_cmd down --remove-orphans || force_remove_container
            docker_compose_cmd up -d
            ;;
        "stop")
            log "BLUE" "⏹️ Остановка контейнера..."
            docker_compose_cmd down --remove-orphans || force_remove_container
            ;;
        "start")
            log "BLUE" "▶️ Запуск контейнера..."
            if [ -n "${BOT_NAME:-}" ] && docker ps -a | grep -q "$BOT_NAME"; then
                force_remove_container
            fi
            docker_compose_cmd up -d
            ;;
    esac

    if [ "$action" = "start" ] || [ "$action" = "restart" ]; then
        log "BLUE" "⏳ Ожидание запуска бота..."
        sleep 5

        if [ -n "${BOT_NAME:-}" ] && ! docker ps | grep -q "$BOT_NAME"; then
            log "RED" "❌ Ошибка запуска контейнера"
            docker_compose_cmd logs
            return 1
        fi

        log "GREEN" "✅ Контейнер запущен"
        docker_compose_cmd logs --tail=10
    fi
}

# Функция для принудительного удаления контейнера
force_remove_container() {
    if docker ps -a | grep -q "$BOT_NAME"; then
        log "YELLOW" "⚠️ Принудительное удаление контейнера $BOT_NAME..."
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
        log "GREEN" "9. 🐳 Проверить и исправить установку Docker"
        log "GREEN" "0. 🚪 Выйти"

        read -r -p "Выберите действие (0-9): " choice

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
            9)
                # Проверка и исправление установки Docker
                check_fix_docker
                ;;
            0)
                log "BLUE" "🚪 Выход..."
                break
                ;;
            *)
                log "RED" "❌ Неверный выбор. Пожалуйста, выберите действие от 0 до 9."
                ;;
        esac
    done
}

# Проверка прав суперпользователя для управления Docker
if [ "$EUID" -ne 0 ] && ! groups | grep -q docker && ! sudo -n true 2>/dev/null; then
    log "YELLOW" "⚠️ Для управления Docker требуются права суперпользователя или членство в группе docker"
    log "YELLOW" "⚠️ Запустите скрипт с sudo или добавьте пользователя в группу docker и перезайдите в систему"
fi

# Запускаем основное меню
main_menu

# Очистка временных файлов перед выходом
cleanup
