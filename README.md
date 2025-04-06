![Built by e-studio.dk](https://img.shields.io/badge/Built%20by-e--studio.dk-blue?style=for-the-badge)
![Assisted by ChatGPT](https://img.shields.io/badge/Assisted%20by-ChatGPT-10a37f?style=for-the-badge&logo=openai&logoColor=white)
![Built in Bash](https://img.shields.io/badge/Built%20with-Bash-4EAA25?style=for-the-badge&logo=gnu-bash&logoColor=white)
# WP Toolkit Maintenance Script

Automated maintenance script for WordPress installations using WP Toolkit.  
Updates plugins, themes, core, clears caches, and checks for outdated PHP versions.

---

## 🇬🇧 English

### Features

- Updates all plugins, themes, and WordPress core.
- Clears WP Toolkit cache for each installation.
- Checks if LiteSpeed Cache plugin is active and clears its cache (if possible).
- Checks installations for outdated PHP versions.
- Logs all operations to daily log files.
- Automatically deletes logs older than 30 days.
- Sends email notifications depending on settings.

### Requirements

- WP Toolkit must be installed on the server.
- `mail` command must be available (for sending emails).
- Must be executed with `bash`, not `sh`.

### Installation

1. Upload the script to the server (e.g., `/root/`).
2. Make the script executable:

    ```bash
    chmod +x wp-toolkit.sh
    ```

3. Run manually:

    ```bash
    ./wp-toolkit.sh all
    ```
    or

    ```bash
    ./wp-toolkit.sh check-php
    ```

### Configuration

At the top of the script (`wp-toolkit.sh`), you can adjust the following settings:

| Variable        | Default value | Description |
|-----------------|----------------|-------------|
| `LOGFILE`        | `/var/log/wp-toolkit-update-YYYY-MM-DD.log` | Path to where logs are saved. One log per day. |
| `EMAIL`         | `support@e-studio.dk` | Email address where notifications are sent. |
| `SEND_MAIL`     | `yes`          | Set to `yes` or `no` to enable or disable sending email notifications. |
| `MAIL_MODE`     | `errors`       | Choose when to send emails: `errors`, `success`, or `both`. |
| `SEND_PHP_MAIL` | `yes`          | Set to `yes` or `no` to enable or disable sending an email if outdated PHP is detected. |

#### Example:

Send email always (both success and error):

```bash
SEND_MAIL="yes"
MAIL_MODE="both"
```

Disable all emails:

```bash
SEND_MAIL="no"
SEND_PHP_MAIL="no"
```

### Automation (Cronjob)

To run the script automatically every **Saturday at 22:30**:

1. Open crontab:

    ```bash
    crontab -e
    ```

2. Add this line:

    ```bash
    30 22 * * 6 /root/wp-toolkit.sh all >> /var/log/wp-toolkit-cron.log 2>&1
    ```

### Usage

| Command                             | Description                                   |
|------------------------------------- |---------------------------------------------- |
| `./wp-toolkit.sh all`                | Update all WordPress installations           |
| `./wp-toolkit.sh all 10`             | Update only the first 10 installations       |
| `./wp-toolkit.sh <domain>`           | Update a specific domain                     |
| `./wp-toolkit.sh check-php`          | Check for outdated PHP versions across all sites |

## Authors

Made by Nicolai from [e-studio.dk](https://e-studio.dk)  
in collaboration with ChatGPT.

---

## 🇩🇰 Dansk

### Funktioner

- Opdaterer alle plugins, temaer og WordPress core.
- Rydder cache for hver installation via WP Toolkit.
- Tjekker om LiteSpeed Cache plugin er aktivt og rydder cachen (hvis muligt).
- Tjekker installationer for forældet PHP-version.
- Logger alle operationer til daglige logfiler.
- Sletter automatisk logs ældre end 30 dage.
- Sender e-mail notifikationer afhængig af indstillinger.

### Krav

- WP Toolkit skal være installeret på serveren.
- `mail` kommando skal være tilgængelig (for at sende e-mails).
- Skal køres med `bash`, ikke `sh`.

### Installation

1. Upload scriptet til serveren (f.eks. `/root/`).
2. Gør scriptet eksekverbart:

    ```bash
    chmod +x wp-toolkit.sh
    ```

3. Kør manuelt:

    ```bash
    ./wp-toolkit.sh all
    ```
    eller

    ```bash
    ./wp-toolkit.sh check-php
    ```

### Konfiguration

Øverst i scriptet (`wp-toolkit.sh`) kan du justere følgende indstillinger:

| Variabel        | Standardværdi | Beskrivelse |
|-----------------|----------------|-------------|
| `LOGFILE`        | `/var/log/wp-toolkit-update-YYYY-MM-DD.log` | Sti hvor logs gemmes. En log pr. dag. |
| `EMAIL`         | `support@e-studio.dk` | E-mail adresse hvor notifikationer sendes til. |
| `SEND_MAIL`     | `yes`          | Sæt til `yes` eller `no` for at slå e-mail notifikationer til eller fra. |
| `MAIL_MODE`     | `errors`       | Vælg hvornår der sendes e-mails: `errors`, `success`, eller `both`. |
| `SEND_PHP_MAIL` | `yes`          | Sæt til `yes` eller `no` for at sende e-mail ved forældet PHP-version. |

#### Eksempel:

Altid send e-mail (både succes og fejl):

```bash
SEND_MAIL="yes"
MAIL_MODE="both"
```

Deaktivér alle e-mails:

```bash
SEND_MAIL="no"
SEND_PHP_MAIL="no"
```

### Automatisering (Cronjob)

For at køre scriptet automatisk hver **lørdag kl. 22:30**:

1. Åbn crontab:

    ```bash
    crontab -e
    ```

2. Tilføj denne linje:

    ```bash
    30 22 * * 6 /root/wp-toolkit.sh all >> /var/log/wp-toolkit-cron.log 2>&1
    ```

### Brug

| Kommando                            | Beskrivelse                                    |
|--------------------------------------|------------------------------------------------|
| `./wp-toolkit.sh all`                | Opdater alle WordPress installationer          |
| `./wp-toolkit.sh all 10`             | Opdater kun de første 10 installationer        |
| `./wp-toolkit.sh <domæne>`           | Opdater et specifikt domæne                    |
| `./wp-toolkit.sh check-php`          | Tjek for forældet PHP-version på alle sites    |

## Forfattere

Lavet af Nicolai fra [e-studio.dk](https://e-studio.dk)  
i samarbejde med ChatGPT.
