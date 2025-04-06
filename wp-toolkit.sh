#!/bin/bash
# ============================================
# WP Toolkit Maintenance Script - Version 2.2
# ============================================

# ----------- Settings ------------
LOGDIR="/var/log"
LOGFILE="$LOGDIR/wp-toolkit-update-$(date +%F).log"
EMAIL="support@e-studio.dk"
SEND_MAIL="yes"        # yes or no
MAIL_MODE="errors"     # errors, success, both
SEND_PHP_MAIL="yes"    # yes or no
RETENTION_DAYS=30      # Delete logs older than X days
# ----------------------------------

# Make sure log directory exists
mkdir -p "$LOGDIR"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $*" | tee -a "$LOGFILE"
}

# Clear old logs
find "$LOGDIR" -name 'wp-toolkit-update-*.log' -mtime +$RETENTION_DAYS -delete

# Run PHP version check
run_php_version_check() {
    log "Checking all installations for outdated PHP versions..."

    local outdated_sites=""
    while IFS= read -r url; do
        site=$(echo "$url" | sed 's|https\?://||')
        outdated_sites="${outdated_sites}\n- ${site}"
    done < <(wp-toolkit --list --format raw | grep "Outdated PHP" | grep -oP 'https://\S+')

    if [ -n "$outdated_sites" ]; then
        log "Outdated PHP installations found:"
        echo -e "$outdated_sites" | tee -a "$LOGFILE"

        if [ "$SEND_PHP_MAIL" == "yes" ]; then
            echo -e "The following installations are running outdated PHP versions:\n$outdated_sites" | mail -s "⚠️ Warning: Outdated PHP detected on server" "$EMAIL"
        fi
    else
        log "No outdated PHP installations found."
    fi
}

# Update a single installation
update_installation() {
    local instance_id=$1
    log "Updating installation ID: $instance_id"

    # Update plugins
    wp-toolkit --wp-cli -instance-id "$instance_id" -- plugin update --all
    # Update themes
    wp-toolkit --wp-cli -instance-id "$instance_id" -- theme update --all
    # Update core
    wp-toolkit --wp-cli -instance-id "$instance_id" -- core update

    # Clear WP Toolkit cache
    wp-toolkit --clear-cache -instance-id "$instance_id"

    # Check if LiteSpeed Cache plugin is active
    if wp-toolkit --wp-cli -instance-id "$instance_id" -- plugin is-active litespeed-cache > /dev/null 2>&1; then
        log "LiteSpeed Cache plugin is active - checking for CLI purge command..."
        if wp-toolkit --wp-cli -instance-id "$instance_id" -- help litespeed-purge > /dev/null 2>&1; then
            wp-toolkit --wp-cli -instance-id "$instance_id" -- litespeed-purge all
            log "LiteSpeed cache cleared for installation ID: $instance_id"
        else
            log "LiteSpeed purge command not available - skipping LiteSpeed cache clear."
        fi
    fi

    log "Finished updating and clearing cache for installation ID: $instance_id"
}

# Exit if no parameters
if [ $# -eq 0 ]; then
    echo "Error: No parameter provided."
    echo "Usage: $0 all [limit] | <domain> | check-php"
    exit 1
fi

# Main script
echo "============================================"
echo " WP Toolkit Maintenance Script - Version 2.2"
echo "============================================"
echo ""

# Handle PHP check
if [ "$1" == "check-php" ]; then
    run_php_version_check
    exit 0
fi

# Variables to track success/failure
PROCESSED_COUNT=0
ERROR_COUNT=0

# Update all installations
if [ "$1" == "all" ]; then
    LIMIT=$2
    log "Starting update of all WordPress installations..."

    if [ -n "$LIMIT" ]; then
        log "Limiting update to the first $LIMIT installations."
    fi

    IDS=$(wp-toolkit --list --format raw | awk 'NR>1 {print $1}')

    for id in $IDS; do
        if [ -n "$LIMIT" ] && [ "$PROCESSED_COUNT" -ge "$LIMIT" ]; then
            break
        fi

        if update_installation "$id"; then
            ((PROCESSED_COUNT++))
        else
            ((ERROR_COUNT++))
        fi
    done

    log "Finished updating."
    log "Total installations processed: $PROCESSED_COUNT"
    log "Total installations with errors: $ERROR_COUNT"
    exit 0
fi

# Update specific domain
DOMAIN=$1
log "Starting update for domain: $DOMAIN"

instance_id=$(wp-toolkit --list --format raw | grep "$DOMAIN" | awk '{print $1}')

if [ -z "$instance_id" ]; then
    log "Error: No WordPress installation found for domain $DOMAIN."
    exit 1
else
    log "Found installation ID: $instance_id for $DOMAIN"
    if update_installation "$instance_id"; then
        log "Finished updating $DOMAIN."
    else
        log "Error updating $DOMAIN."
    fi
fi
