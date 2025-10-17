# Telegram Support Bot

Telegram бот для технической поддержки с интеграцией форума и приватных чатов.

## 🚀 Быстрый старт

### Быстрый старт
```bash
curl -sSL https://raw.githubusercontent.com/gopnikgame/support-bot/main/launcher.sh -o launcher.sh && chmod +x launcher.sh && ./launcher.sh
```
### Установка
```bash
# Установка основного экземпляра
sudo bash launcher.sh

# Установка именованного экземпляра (для нескольких ботов)
sudo bash launcher.sh instance_name
```

### Управление

После установки используйте скрипт управления:

```bash
# Управление основным экземпляром
cd /opt/support-bot
./manage_bot.sh

# Управление именованным экземпляром
cd /opt/support-bot_instance_name
./manage_bot.sh instance_name
```

## 📋 Требования

- Ubuntu 18.04+ или Debian 10+
- Docker CE
- Docker Compose
- Git

Все зависимости устанавливаются автоматически при запуске `launcher.sh`.

## ⚙️ Конфигурация

Отредактируйте файл `.env`:

```bash
BOT_TOKEN=your_bot_token_here
BOT_DEV_ID=your_dev_id_here
BOT_GROUP_ID=your_group_id_here
BOT_EMOJI_ID=5417915203100613993
BOT_NAME=support-bot

REDIS_HOST=redis
REDIS_PORT=6379
REDIS_DB=0
```

## 🔧 Функции управления

После запуска `manage_bot.sh` доступны следующие опции:

1. **⬆️ Обновить из репозитория** - получить последнюю версию
2. **📝 Создать/редактировать .env** - настроить конфигурацию
3. **🚀 Запустить бота** - собрать и запустить Docker контейнер
4. **⏹️ Остановить бота** - остановить и удалить контейнер
5. **📊 Показать логи** - просмотр всех логов
6. **❌ Показать ошибки** - просмотр только ошибок
7. **🔄 Перезапустить** - быстрый перезапуск бота
8. **🧹 Очистить логи** - архивация и очистка старых логов
9. **🐳 Проверить Docker** - диагностика установки Docker
0. **🚪 Выйти** - выход из меню

## 🔁 Несколько экземпляров

Вы можете запустить несколько независимых экземпляров бота:

```bash
# Production
sudo bash launcher.sh production

# Development
sudo bash launcher.sh development

# Testing
sudo bash launcher.sh testing
```

Каждый экземпляр будет иметь:
- Свою директорию: `/opt/support-bot_<name>`
- Свои контейнеры: `support-bot_<name>` и `support-bot_<name>-redis`
- Свой лог-файл: `/var/log/support-bot_<name>.log`
- Свой `.env` файл


## 🐛 Устранение неполадок

### Docker установлен через snap
Скрипт автоматически предложит переустановить Docker с официального репозитория.

### Проблемы с правами
```bash
# Добавьте пользователя в группу docker
sudo usermod -aG docker $USER

# Перезайдите или выполните
newgrp docker
```

### Контейнер не запускается
```bash
# Проверьте логи
cd /opt/support-bot
./manage_bot.sh
# Выберите пункт 5 (Показать логи)

# Проверьте статус Docker
sudo systemctl status docker

# Проверьте .env файл
cat .env
```

## 🔒 Безопасность

- ⚠️ Файл `.env` содержит конфиденциальные данные
- ⚠️ Не добавляйте `.env` в git
- ⚠️ Используйте разные токены для разных экземпляров
- ⚠️ Регулярно обновляйте систему: `sudo apt update && sudo apt upgrade`

## 📝 Логи

Логи хранятся в нескольких местах:

- **Логи установки**: `/var/log/support-bot.log`
- **Логи приложения**: `/opt/support-bot/logs/`
- **Архивы логов**: `/opt/support-bot/logs_backup/`
- **Docker логи**: `docker logs support-bot`

## 🔄 Обновление

```bash
cd /opt/support-bot
./manage_bot.sh
# Выберите пункт 1 (Обновить из репозитория)
# Затем пункт 7 (Перезапустить)
```

## 💾 Backup

### Конфигурация
```bash
sudo cp /opt/support-bot/.env /opt/support-bot/.env.backup
```

### Данные Redis
```bash
sudo tar -czf redis_backup.tar.gz /opt/support-bot/redis/data/
```

## 🤝 Поддержка

При возникновении проблем:
1. Проверьте логи
2. Проверьте конфигурацию `.env`
3. Создайте issue в GitHub

## 📄 Лицензия

MIT License - см. [LICENSE](./LICENSE)

## 👨‍💻 Автор

Оригинальный проект: [nessshon/support-bot](https://github.com/nessshon/support-bot)

Fork: [gopnikgame/support-bot](https://github.com/gopnikgame/support-bot)

---

**Примечание**: Этот README относится к форку с улучшениями в скриптах установки и управления.
