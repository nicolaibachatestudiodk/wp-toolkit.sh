#!/bin/bash

# Filnavn: /root/wp-toolkit.sh
# Version: 1.8
# Sidst opdateret: 2025-04-06

TODAY=$(date '+%Y-%m-%d')
LOGFILE="/var/log/wp-toolkit-update-$TODAY.log"
EMAIL="email@domain.dk"

# -- Variabler du kan styre --
SEND_MAIL="yes"          # yes eller no
MAIL_MODE="errors"       # errors = kun fejl, success = kun succes, both = altid
SEND_PHP_MAIL="yes"      # yes eller no (send mail hvis outdated PHP findes)
# ----------------------------

# ------------------------
# Version header
# ------------------------

echo "============================================"
echo " WP Toolkit Maintenance Script - Version 1.8"
echo "============================================"
echo ""

# ------------------------
# Log funktion
# ------------------------

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" | tee -a "$LOGFILE"
}

# ------------------------
# Slet logs ældre end 30 dage
# ------------------------

find /var/log/ -name 'wp-toolkit-update-*.log' -mtime +30 -delete

# ------------------------
# Opret logfil hvis den ikke findes
# ------------------------

if [ ! -f "$LOGFILE" ]; then
    touch "$LOGFILE"
    chmod 600 "$LOGFILE"
fi

# ------------------------
# Tjek om wp-toolkit findes
# ------------------------

if ! command -v wp-toolkit &> /dev/null; then
    echo "Fejl: wp-toolkit kommandoen blev ikke fundet." | tee -a "$LOGFILE"
    if [ "$SEND_MAIL" == "yes" ]; then
        echo "wp-toolkit kommandoen blev ikke fundet." | mail -s "❌ WP Toolkit fejl på serveren" "$EMAIL"
    fi
    exit 1
fi

# ------------------------
# Tjek at der er et parameter
# ------------------------

if [ -z "$1" ]; then
    echo "Fejl: Ingen parameter angivet." | tee -a "$LOGFILE"
    echo ""
    echo "Brug: "
    echo "  sh wp-toolkit.sh all              # Opdater ALLE installationer"
    echo "  sh wp-toolkit.sh all <antal>      # Opdater KUN de første <antal> installationer"
    echo "  sh wp-toolkit.sh <domæne>         # Opdater specifikt domæne"
    echo "  sh wp-toolkit.sh check-php        # Tjek for forældet PHP-version"
    echo ""
    exit 1
fi

# ------------------------
# check-php funktion
# ------------------------

if [ "$1" == "check-php" ]; then
    log "Tjekker alle installationer for forældet PHP-version..."

    PHP_OUTDATED=""

    while read -r URL; do
        if [ -n "$URL" ]; then
            DOMAIN=$(echo "$URL" | sed 's~https\?://~~;s~/.*~~')
            PHP_OUTDATED="$PHP_OUTDATED\n- $DOMAIN"
        fi
    done < <(wp-toolkit --list --format raw | grep "Outdated PHP" | grep -oP 'https://\S+')

    if [ -n "$PHP_OUTDATED" ]; then
        log "Installationer med forældet PHP fundet:"
        echo -e "$PHP_OUTDATED" | tee -a "$LOGFILE"

        if [ "$SEND_PHP_MAIL" == "yes" ]; then
            echo -e "Følgende installationer kører med forældet PHP:\n$PHP_OUTDATED" | mail -s "⚠️ Advarsel: Forældet PHP fundet på serveren" "$EMAIL"
        fi
    else
        log "Ingen installationer med forældet PHP fundet."
    fi

    exit 0
fi

# ------------------------
# Hvis input er 'all' eller domæne
# ------------------------

update_instance() {
    local ID=$1
    log "Opdaterer installation ID: $ID"

    wp-toolkit --wp-cli -instance-id "$ID" -- plugin update --all 2>&1 | tee -a "$LOGFILE"
    wp-toolkit --wp-cli -instance-id "$ID" -- theme update --all 2>&1 | tee -a "$LOGFILE"
    wp-toolkit --wp-cli -instance-id "$ID" -- core update 2>&1 | tee -a "$LOGFILE"

    wp-toolkit --clear-cache -instance-id "$ID" 2>&1 | tee -a "$LOGFILE"

    if wp-toolkit --wp-cli -instance-id "$ID" -- plugin is-active litespeed-cache > /dev/null 2>&1; then
        log "LiteSpeed Cache plugin er aktivt - forsøger at rydde LiteSpeed cache"
        if ! wp-toolkit --wp-cli -instance-id "$ID" -- litespeed-purge all > /dev/null 2>&1; then
            log "LiteSpeed CLI ikke installeret - springer cache clear over."
        else
            log "LiteSpeed cache ryddet."
        fi
    else
        log "LiteSpeed Cache plugin ikke aktivt - ingen cache clear"
    fi

    log "Færdig med opdatering og cache clear for installation ID: $ID"
}

if [ "$1" == "all" ]; then
    log "Starter opdatering af ALLE WordPress installationer..."

    TOTAL=0
    ERROR_COUNT=0
    FAILED_DOMAINS=""

    LIMIT="$2"

    if [ -n "$LIMIT" ]; then
        log "Begrænser opdatering til de første $LIMIT installationer."
        IDS=$(wp-toolkit --list | awk '{print $1}' | tail -n +2 | head -n "$LIMIT")
    else
        IDS=$(wp-toolkit --list | awk '{print $1}' | tail -n +2)
    fi

    echo "$IDS" | while read id; do
        if [ -n "$id" ]; then
            DOMAIN=$(wp-toolkit --list | grep "^$id " | awk '{print $8}')
            update_instance "$id"
            TOTAL=$((TOTAL + 1))

            if tail -n 20 "$LOGFILE" | grep -iq "fejl"; then
                ERROR_COUNT=$((ERROR_COUNT + 1))
                FAILED_DOMAINS="$FAILED_DOMAINS\n- $DOMAIN"
            fi
        fi
    done

    log "Færdig med opdatering."
    log "Antal installationer behandlet: $TOTAL"
    log "Antal installationer med fejl: $ERROR_COUNT"

    if [ "$ERROR_COUNT" -gt 0 ]; then
        log "Fejl på følgende domæner:$(echo -e "$FAILED_DOMAINS")"
    fi
else
    DOMAIN=$1
    log "Starter opdatering for domæne: $DOMAIN"

    ID=$(wp-toolkit --list | grep -w "$DOMAIN" | awk '{print $1}')

    if [ -z "$ID" ]; then
        log "Fejl: Kunne ikke finde WordPress installation for domænet $DOMAIN"
        if [ "$SEND_MAIL" == "yes" ]; then
            echo "Fejl: Kunne ikke finde WordPress installation for $DOMAIN" | mail -s "❌ Fejl ved opdatering af $DOMAIN" "$EMAIL"
        fi
        exit 1
    fi

    log "Fundet installation ID: $ID for $DOMAIN"
    update_instance "$ID"

    log "Færdig med opdatering for $DOMAIN."
fi

# ------------------------
# E-mail notifikation hvis ønsket
# ------------------------

if [ "$SEND_MAIL" == "yes" ]; then
    if [ "$MAIL_MODE" == "errors" ]; then
        if grep -iq "fejl" "$LOGFILE"; then
            mail -s "❌ Fejl under WordPress opdatering" "$EMAIL" < "$LOGFILE"
        fi
    elif [ "$MAIL_MODE" == "success" ]; then
        if ! grep -iq "fejl" "$LOGFILE"; then
            mail -s "✅ WordPress opdatering gennemført uden fejl" "$EMAIL" < "$LOGFILE"
        fi
    elif [ "$MAIL_MODE" == "both" ]; then
        mail -s "ℹ️ WordPress opdatering status" "$EMAIL" < "$LOGFILE"
    fi
fi

exit 0
