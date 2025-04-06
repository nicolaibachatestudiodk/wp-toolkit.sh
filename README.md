# WP Toolkit Maintenance Script

**Bash script til automatisk vedligeholdelse af WordPress installationer via WP Toolkit.**

---

## 🇩🇰 Dansk

### Funktioner

- Opdaterer alle plugins, temaer og WordPress core.
- Rydder cache på installationerne.
- Tjekker om LiteSpeed Cache plugin er aktivt og rydder cachen.
- Tjekker installationer for forældet PHP-version.
- Logger alle operationer til filer (og sletter logs ældre end 30 dage).
- Sender e-mail ved fejl eller succes, afhængig af opsætning.

### Krav

- WP Toolkit skal være installeret.
- `mail` kommando skal være installeret for e-mails.
- Scriptet skal køres med `bash`, ikke `sh`.

### Installation

1. Upload scriptet til serveren (f.eks. i `/root/`).
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

---

## 🇬🇧 English

### Features

- Updates all plugins, themes, and WordPress core.
- Clears cache for each installation.
- Checks if LiteSpeed Cache plugin is active and clears its cache.
- Checks installations for outdated PHP versions.
- Logs all operations to files (and deletes logs older than 30 days).
- Sends email notifications for errors or success depending on setup.

### Requirements

- WP Toolkit must be installed.
- `mail` command must be installed for email notifications.
- Must be executed using `bash`, not `sh`.

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
