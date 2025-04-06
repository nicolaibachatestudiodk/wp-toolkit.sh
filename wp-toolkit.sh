#!/bin/bash

# File: /root/wp-toolkit.sh
# Version: 2.1
# Last updated: 2025-04-06

# Check if running under Bash
if [ -z "$BASH_VERSION" ]; then
  echo "Error: Please run this script with bash, not sh."
  exit 1
fi

TODAY=$(date '+%Y-%m-%d')
LOGFILE="/var/log/wp-toolkit-update-$TODAY.log" # Log location
EMAIL="email@domain.dk" # Email

# -- Settings --
SEND_MAIL="yes"          # yes or no
MAIL_MODE="errors"       # errors, success, or both
SEND_PHP_MAIL="yes"      # yes or no (send mail if outdated PHP is detected)
# ----------------

# ----------------
# Version Header
# ----------------

echo "============================================"
echo " WP Toolkit Maintenance Script - Version 2.1"
echo "============================================"
echo ""

# ----------------
# Log Function
# ----------------

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGFILE"
}

# ----------------
# Clean up old logs
# ----------------

find /var/log/ -name 'wp-toolkit-update-*.log' -mtime +30 -delete

# ----------------
# Ensure log file exists
# ----------------

if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
    chmod 600 "$LOGFILE"
fi

# ----------------
# Check for wp-toolkit command
# ----------------

if ! command -v wp-toolkit &> /dev/null; then
    echo "Error: wp-toolkit command not found." | tee -a "$LOGFILE"
    if [ "$SEND_MAIL" == "yes" ]; then
        echo "wp-toolkit command not found on server." | mail -s "❌ WP Toolkit error" "$EMAIL"
    fi
    exit 1
fi

# ----------------
# Validate input
# ----------------

if [ -z "$1" ]; then
    echo "Error: No parameter provided." | tee -a "$LOGFILE"
    echo ""
    echo "Usage:"
    echo "  ./wp-toolkit.sh all              # Update all WordPress installations"
    echo "  ./wp-toolkit.sh all <limit>      # Update only the first <limit> installations"
    echo "  ./wp-toolkit.sh <domain>         # Update specific domain"
    echo "  ./wp-toolkit.sh check-php        # Check for outdated PHP versions"
    echo ""
    exit 1
fi

# ----------------
# Check outdated PHP
# ----------------

if [ "$1" == "check-php" ]; then
    log "Checking all installations for outdated PHP versions..."

    PHP_OUTDATED=""

    while read -r URL; do
        if [ -n "$URL" ]; then
            DOMAIN=$(echo "$URL" | sed 's~https\?://~~;s~/.*~~')
            PHP_OUTDATED="$PHP_OUTDATED\n- $DOMAIN"
        fi
    done < <(wp-toolkit --list --format raw | grep "Outdated PHP" | grep -oP 'https://\S+')

    if [ -n "$PHP_OUTDATED" ]; then
        log "Outdated PHP installations found:"
        echo -e "$PHP_OUTDATED" | tee -a "$LOGFILE"

        if [ "$SEND_PHP_MAIL" == "yes" ]; then
            echo -e "The following installations are running outdated PHP versions:\n$PHP_OUTDATED" | mail -s "⚠️ Outdated PHP detected on server" "$EMAIL"
        fi
    else
        log "No installations with outdated PHP detected."
    fi

    exit 0
fi

# ----------------
# Update Function
# ----------------

update_instance() {
    local ID=$1
    log "Updating installation ID: $ID"

    wp-toolkit --wp-cli -instance-id "$ID" -- plugin update --all 2>&1 | tee -a "$LOGFILE"
    wp-toolkit --wp-cli -instance-id "$ID" -- theme update --all 2>&1 | tee -a "$LOGFILE"
    wp-toolkit --wp-cli -instance-id "$ID" -- core update 2>&1 | tee -a "$LOGFILE"

    wp-toolkit --clear-cache -instance-id "$ID" 2>&1 | tee -a "$LOGFILE"

    if wp-toolkit --wp-cli -instance-id "$ID" -- plugin is-active litespeed-cache > /dev/null 2>&1; then
        log "LiteSpeed Cache plugin is active - checking for CLI purge command..."
        
        if wp-toolkit --wp-cli -instance-id "$ID" -- help | grep -q "litespeed-purge"; then
            if wp-toolkit --wp-cli -instance-id "$ID" -- litespeed-purge all > /dev/null 2>&1; then
                log "LiteSpeed cache successfully purged."
            else
                log "Error while purging LiteSpeed cache."
            fi
        else
            log "LiteSpeed purge command not available - skipping LiteSpeed cache clear."
        fi
    else
        log "LiteSpeed Cache plugin is not active - skipping LiteSpeed cache clear."
    fi

    log "Finished updating and clearing cache for installation ID: $ID"
}

# ----------------
# Main Execution
# ----------------

if [ "$1" == "all" ]; then
    log "Starting update of all WordPress installations..."

    TOTAL=0
    ERROR_COUNT=0
    FAILED_DOMAINS=""

    LIMIT="$2"

    if [ -n "$LIMIT" ]; then
        log "Limiting update to the first $LIMIT installations."
        IDS=$(wp-toolkit --list | awk '{print $1}' | tail -n +2 | head -n "$LIMIT")
    else
        IDS=$(wp-toolkit --list | awk '{print $1}' | tail -n +2)
    fi

    echo "$IDS" | while read id; do
        if [ -n "$id" ]; then
            DOMAIN=$(wp-toolkit --list | grep "^$id " | awk '{print $8}')
            update_instance "$id"
            TOTAL=$((TOTAL + 1))

            if tail -n 20 "$LOGFILE" | grep -iq "error"; then
                ERROR_COUNT=$((ERROR_COUNT + 1))
                FAILED_DOMAINS="$FAILED_DOMAINS\n- $DOMAIN"
            fi
        fi
    done

    log "Finished updating."
    log "Total installations processed: $TOTAL"
    log "Total installations with errors: $ERROR_COUNT"

    if [ "$ERROR_COUNT" -gt 0 ]; then
        log "Errors occurred on the following domains:$(echo -e "$FAILED_DOMAINS")"
    fi

else
    DOMAIN=$1
    log "Starting update for domain: $DOMAIN"

    ID=$(wp-toolkit --list | grep -w "$DOMAIN" | awk '{print $1}')

    if [ -z "$ID" ]; then
        log "Error: Could not find WordPress installation for domain $DOMAIN"
        if [ "$SEND_MAIL" == "yes" ]; then
            echo "Error: Could not find WordPress installation for domain $DOMAIN" | mail -s "❌ Error updating $DOMAIN" "$EMAIL"
        fi
        exit 1
    fi

    log "Found installation ID: $ID for $DOMAIN"
    update_instance "$ID"

    log "Finished updating domain: $DOMAIN"
fi

# ----------------
# Email Notifications
# ----------------

if [ "$SEND_MAIL" == "yes" ]; then
    if [ "$MAIL_MODE" == "errors" ]; then
        if grep -iq "error" "$LOGFILE"; then
            mail -s "❌ WordPress Update Error" "$EMAIL" < "$LOGFILE"
        fi
    elif [ "$MAIL_MODE" == "success" ]; then
        if ! grep -iq "error" "$LOGFILE"; then
            mail -s "✅ WordPress Update Successful" "$EMAIL" < "$LOGFILE"
        fi
    elif [ "$MAIL_MODE" == "both" ]; then
        mail -s "ℹ️ WordPress Update Report" "$EMAIL" < "$LOGFILE"
    fi
fi

exit 0
