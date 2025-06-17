# 🤖 Support Bot | Бот поддержки

[![License](https://img.shields.io/github/license/gopnikgame/support-bot)](https://github.com/gopnikgame/support-bot/blob/main/LICENSE)
[![Telegram Bot](https://img.shields.io/badge/Bot-grey?logo=telegram)](https://core.telegram.org/bots)
[![Python](https://img.shields.io/badge/Python-3.10-blue.svg)](https://www.python.org/downloads/release/python-3100/)
[![Redis](https://img.shields.io/badge/Redis-Yes?logo=redis&color=white)](https://redis.io/)
[![Docker](https://img.shields.io/badge/Docker-blue?logo=docker&logoColor=white)](https://www.docker.com/)

## 🇬🇧 English

**Support Bot** is a specially developed Telegram bot for feedback management. With built-in topic support, all user messages are efficiently distributed by category, promoting organized and structured discussions in your group. It provides features such as blocking unwanted users, silent mode in topics for discreet conversations, and much more. Enhance group communication with Support Bot!

Quick start:
```bash
curl -s https://raw.githubusercontent.com/gopnikgame/support-bot/main/launcher.sh -o /tmp/launcher.sh && sudo bash /tmp/launcher.sh
```

Multiple bots on one server:
```bash
curl -s https://raw.githubusercontent.com/gopnikgame/support-bot/main/launcher.sh -o /tmp/launcher.sh && sudo bash /tmp/launcher.sh 2
```

Install bot with custom name
```bash
curl -s https://raw.githubusercontent.com/gopnikgame/support-bot/main/launcher.sh -o /tmp/launcher.sh && sudo bash /tmp/launcher.sh project1
```

**About Limits**:
<blockquote>
Specific limits are not specified in the documentation, but the community has shared some rough numbers. 
<br>
• Limit on topic creation per minute <b>~20</b>.
<br>
• Limit on the total number of topics <b>~1M</b>.
</blockquote>

<details>
<summary><b>Available bot commands for admins (DEV_ID)</b></summary>

* `/newsletter` - Open the newsletter menu.

  Use this command to initiate a newsletter for users.
  **Note**: This command works only in private chats.

</details>

<details>
<summary><b>Available bot commands in the group topics</b></summary>

* `/ban` - Block/Unblock User.

  Use this command to block or unblock a user, controlling the receipt of messages from them.

* `/silent` - Activate/Deactivate Silent Mode.

  Enable or disable silent mode to prevent messages from being sent to the user.

* `/information` - User Information.

  Receive a message containing basic information about the user.

</details>

## 🇷🇺 Русский

**Support Bot** - это специально разработанный Telegram-бот для обратной связи. Благодаря встроенной поддержке тем все сообщения пользователей грамотно распределяются по категориям, способствуя организованному и упорядоченному обсуждению в вашей группе. Он предоставляет такие функции, как блокировка нежелательных пользователей, беззвучный режим в темах для незаметных разговоров и многое другое. Улучшите общение в группе с помощью Support Bot!

Быстрый старт: 
```bash
curl -s https://raw.githubusercontent.com/gopnikgame/support-bot/main/launcher.sh -o /tmp/launcher.sh && sudo bash /tmp/launcher.sh
```

Несколько ботов на одном сервере:
Установка дополнительного экземпляра бота с числовым суффиксом
```bash
curl -s https://raw.githubusercontent.com/gopnikgame/support-bot/main/launcher.sh -o /tmp/launcher.sh && sudo bash /tmp/launcher.sh 2
```

Установка бота с пользовательским названием
```bash
curl -s https://raw.githubusercontent.com/gopnikgame/support-bot/main/launcher.sh -o /tmp/launcher.sh && sudo bash /tmp/launcher.sh project1
```

**О лимитах**:
<blockquote>
Конкретные ограничения не указаны в документации, но сообщество поделилось примерными цифрами.
<br>
• Лимит создания тем в минуту <b>~20</b>.
<br>
• Лимит на общее количество тем <b>~1M</b>.
</blockquote>

<details>
<summary><b>Доступные команды бота для администраторов (DEV_ID)</b></summary>

* `/newsletter` - Открыть меню рассылки.

  Используйте эту команду для инициирования рассылки пользователям.
  **Примечание**: Эта команда работает только в приватных чатах.

</details>

<details>
<summary><b>Доступные команды бота в темах группы</b></summary>

* `/ban` - Заблокировать/Разблокировать пользователя.

  Используйте эту команду для блокировки или разблокировки пользователя, контролируя получение сообщений от него.

* `/silent` - Активировать/Деактивировать беззвучный режим.

  Включите или отключите беззвучный режим, чтобы предотвратить отправку сообщений пользователю.

* `/information` - Информация о пользователе.

  Получение сообщения с основной информацией о пользователе.

</details>

## Usage | Использование

<details>
<summary><b>Preparation | Подготовка</b></summary>

1. Create a bot via [@BotFather](https://t.me/BotFather) and save the TOKEN (referred to as `BOT_TOKEN` later).
   
   Создайте бота через [@BotFather](https://t.me/BotFather) и сохраните TOKEN (далее упоминается как `BOT_TOKEN`).

2. Create a group and enable topics in the group settings.
   
   Создайте группу и включите темы в настройках группы.

3. Add the created bot to the group as an admin and grant it the necessary rights to manage topics.
   
   Добавьте созданного бота в группу как администратора и предоставьте ему необходимые права для управления темами.

4. Add the bot [What's my Telegram ID?](https://t.me/my_id_bot) to the group and save the group ID (referred to as `BOT_GROUP_ID` later).
   
   Добавьте бота [What's my Telegram ID?](https://t.me/my_id_bot) в группу и сохраните ID группы (далее упоминается как `BOT_GROUP_ID`).

5. Optionally, customize the bot texts to fit your needs in the file named [texts](https://github.com/gopnikgame/support-bot/tree/main/app/bot/utils/texts.py).
   
   При необходимости настройте тексты бота под ваши нужды в файле [texts](https://github.com/gopnikgame/support-bot/tree/main/app/bot/utils/texts.py).

6. Optionally, add the language you need to [SUPPORTED_LANGUAGES](https://github.com/gopnikgame/support-bot/tree/main/app/bot/utils/texts.py#L4) and add the appropriate codes to the [data](https://github.com/gopnikgame/support-bot/tree/main/app/bot/utils/texts.py#L49).
   
   При необходимости добавьте нужный вам язык в [SUPPORTED_LANGUAGES](https://github.com/gopnikgame/support-bot/tree/main/app/bot/utils/texts.py#L4) и добавьте соответствующие коды в [data](https://github.com/gopnikgame/support-bot/tree/main/app/bot/utils/texts.py#L49).

</details>

<details>
<summary><b>Installation | Установка</b></summary>

1. Clone the repository:
   
   Клонируйте репозиторий:
   ```bash
      git clone https://github.com/gopnikgame/support-bot.git
   ```
2. Change into the bot directory:
   
   Перейдите в директорию бота:
   ```bash
      cd support-bot
   ```
3. Clone environment variables file:
   
   Создайте файл переменных окружения из примера:
   ```bash
      cp .env.example .env
   ```
4. Configure [environment variables](#environment-variables-reference) in the file:
   
   Настройте [переменные окружения](#environment-variables-reference) в файле:
   ```bash
      nano .env
   ```
5. Running a bot in a docker container:
   
   Запуск бота в docker-контейнере:
   ```bash
      docker-compose up --build
   ```
</details>

<details>
<summary><b>Bot Management Script | Скрипт управления ботом</b></summary>

The bot comes with a convenient management script `manage_bot.sh` which provides an easy-to-use menu for various operations:

Бот поставляется с удобным скриптом управления `manage_bot.sh`, который предоставляет простое в использовании меню для различных операций:

1. Update from repository | Обновление из репозитория
2. Create or edit .env file | Создать или редактировать файл .env
3. Build and start bot container | Собрать и запустить контейнер бота
4. Stop and remove bot container | Остановить и удалить контейнер бота
5. Show all logs | Показать все логи
6. Show error logs | Показать логи ошибок 
7. Restart bot | Перезапустить бота
8. Clean old logs and backups | Очистить старые логи и бэкапы
9. Check and fix Docker installation | Проверить и исправить установку Docker

To use the script, simply run:

Для использования скрипта просто выполните:

```bash
curl -s https://raw.githubusercontent.com/gopnikgame/support-bot/main/launcher.sh -o /tmp/launcher.sh && sudo bash /tmp/launcher.sh
```

</details>

## Environment Variables Reference | Справочник переменных окружения

<details>
<summary><b>Click to expand | Нажмите, чтобы развернуть</b></summary>

Here is a comprehensive reference guide for the environment variables used in the project:

Вот подробный справочник по переменным окружения, используемым в проекте:

| Variable       | Type  | Description                                                   | Example               |
|----------------|-------|---------------------------------------------------------------|-----------------------|
| `BOT_TOKEN`    | `str` | Bot token, obtained from [@BotFather](https://t.me/BotFather) | `123456:qweRTY`       | 
| `BOT_DEV_ID`   | `int` | User ID of the bot developer or admin                         | `123456789`           |
| `BOT_GROUP_ID` | `str` | Group ID where the bot operates                               | `-100123456789`       |
| `BOT_EMOJI_ID` | `str` | The custom emoji ID for the group's topic.                    | `5417915203100613993` |
| `BOT_NAME`     | `str` | Name for the docker container                                 | `support-bot`         |
| `REDIS_HOST`   | `str` | The hostname or IP address of the Redis server                | `redis`               |
| `REDIS_PORT`   | `int` | The port number on which the Redis server is running          | `6379`                |
| `REDIS_DB`     | `int` | The Redis database number                                     | `1`                   |

<details>
<summary>List of supporting custom emoji ID's | Список поддерживаемых ID эмодзи</summary>

`5434144690511290129` - 📰

`5312536423851630001` - 💡

`5312016608254762256` - ⚡️

`5377544228505134960` - 🎙

`5418085807791545980` - 🔝

`5370870893004203704` - 🗣

`5420216386448270341` - 🆒

`5379748062124056162` - ❗️

`5373251851074415873` - 📝

`5433614043006903194` - 📆

`5357315181649076022` - 📁

`5309965701241379366` - 🔎

`5309984423003823246` - 📣

`5312241539987020022` - 🔥

`5312138559556164615` - ❤️

`5377316857231450742` - ❓

`5350305691942788490` - 📈

`5350713563512052787` - 📉

`5309958691854754293` - 💎

`5350452584119279096` - 💰

`5309929258443874898` - 💸

`5377690785674175481` - 🪙

`5310107765874632305` - 💱

`5377438129928020693` - ⁉️

`5309950797704865693` - 🎮

`5350554349074391003` - 💻

`5409357944619802453` - 📱

`5312322066328853156` - 🚗

`5312486108309757006` - 🏠

`5310029292527164639` - 💘

`5310228579009699834` - 🎉

`5377498341074542641` - ‼️

`5312315739842026755` - 🏆

`5408906741125490282` - 🏁

`5368653135101310687` - 🎬

`5310045076531978942` - 🎵

`5420331611830886484` - 🔞

`5350481781306958339` - 📚

`5357107601584693888` - 👑

`5375159220280762629` - ⚽️

`5384327463629233871` - 🏀

`5350513667144163474` - 📺

`5357121491508928442` - 👀

`5357185426392096577` - 🫦

`5310157398516703416` - 🍓

`5310262535021142850` - 💄

`5368741306484925109` - 👠

`5348436127038579546` - ✈️

`5357120306097956843` - 🧳

`5310303848311562896` - 🏖

`5350424168615649565` - ⛅️

`5413625003218313783` - 🦄

`5350699789551935589` - 🛍

`5377478880577724584` - 👜

`5431492767249342908` - 🛒

`5350497316203668441` - 🚂

`5350422527938141909` - 🛥

`5418196338774907917` - 🏔

`5350648297189023928` - 🏕

`5309832892262654231` - 🤖

`5350751634102166060` - 🪩

`5377624166436445368` - 🎟

`5386395194029515402` - 🏴

`5350387571199319521` - 🗳

`5357419403325481346` - 🎓

`5368585403467048206` - 🔭

`5377580546748588396` - 🔬

`5377317729109811382` - 🎶

`5382003830487523366` - 🎤

`5357298525765902091` - 🕺

`5357370526597653193` - 💃

`5357188789351490453` - 🪖

`5348227245599105972` - 💼

`5411138633765757782` - 🧪

`5386435923204382258` - 👨

`5377675010259297233` - 👶

`5386609083400856174` - 🤰

`5368808634392257474` - 💅

`5350548830041415279` - 🏛

`5355127101970194557` - 🧮

`5386379624773066504` - 🖨

`5377494501373780436` - 👮

`5350307998340226571` - 🩺

`5310094636159607472` - 💊

`5310139157790596888` - 💉

`5377468357907849200` - 🧼

`5418115271267197333` - 🪪

`5372819184658949787` - 🛃

`5350344462612570293` - 🍽

`5384574037701696503` - 🐟

`5310039132297242441` - 🎨

`5350658016700013471` - 🎭

`5357504778685392027` - 🎩

`5350367161514732241` - 🔮

`5350520238444126134` - 🍹

`5310132165583840589` - 🎂

`5350392020785437399` - ☕️

`5350406176997646350` - 🍣

`5350403544182694064` - 🍔

`5350444672789519765` - 🍕

`5312424913615723286` - 🦠

`5417915203100613993` - 💬

`5312054580060625569` - 🎄

`5309744892677727325` - 🎃

`5238156910363950406` - ✍️

`5235579393115438657` - ⭐️

`5237699328843200968` - ✅

`5238027455754680851` - 🎖

`5238234236955148254` - 🤡

`5237889595894414384` - 🧠

`5237999392438371490` - 🦮

`5235912661102773458` - 🐈

</details>

</details>

## Contribution | Вклад в проект

We welcome your contributions! If you have ideas for improvement or have identified a bug, please create an issue or submit a pull request.

Мы приветствуем ваш вклад! Если у вас есть идеи по улучшению или вы обнаружили ошибку, создайте issue или отправьте pull request.

## Acknowledgements | Благодарности

This project is based on the original [Support Bot](https://github.com/nessshon/support-bot) by [@nessshon](https://github.com/nessshon). We express our sincere gratitude for the excellent foundation provided by the original author.

Этот проект основан на оригинальном [Support Bot](https://github.com/nessshon/support-bot) от [@nessshon](https://github.com/nessshon). Мы выражаем искреннюю благодарность за отличную основу, предоставленную оригинальным автором.

## License | Лицензия

This repository is distributed under the [MIT License](LICENSE).
Feel free to use, modify, and distribute the code in accordance with the terms of the license.

Этот репозиторий распространяется под [лицензией MIT](LICENSE).
Вы можете свободно использовать, изменять и распространять код в соответствии с условиями лицензии.
