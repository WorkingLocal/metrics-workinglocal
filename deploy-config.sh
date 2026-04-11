#!/bin/bash
# Deploy Netdata configuratie naar VPS
# Gebruik: bash deploy-config.sh <VPS-IP> [--smtp-password <wachtwoord>]
#
# Vereisten: SSH toegang tot de VPS als root

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'
log()  { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }

VPS_IP="${1:-23.94.220.181}"
SMTP_PASSWORD="${3}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "=== Netdata config deployen naar ${VPS_IP} ==="

# Netdata container naam ophalen
NETDATA=$(ssh root@"$VPS_IP" "docker ps --filter name=netdata --format '{{.Names}}' | head -1")
[[ -z "$NETDATA" ]] && { echo "Netdata container niet gevonden"; exit 1; }

# Config volume path ophalen
CONFIG_VOL=$(ssh root@"$VPS_IP" "docker inspect $NETDATA | python3 -c \"
import json,sys
d=json.load(sys.stdin)[0]
for m in d['Mounts']:
    if '/etc/netdata' in m.get('Destination',''):
        print(m.get('Source',''))
        break
\"")
[[ -z "$CONFIG_VOL" ]] && { echo "Netdata config volume niet gevonden"; exit 1; }

log "Netdata container: $NETDATA"
log "Config volume: $CONFIG_VOL"

# Bestanden kopiëren
echo "→ netdata.conf kopiëren..."
scp "$SCRIPT_DIR/netdata/netdata.conf" root@"$VPS_IP":"$CONFIG_VOL/netdata.conf"
log "netdata.conf gekopieerd"

# Health alerts kopiëren
echo "→ Health alerts kopiëren..."
ssh root@"$VPS_IP" "mkdir -p $CONFIG_VOL/health.d"
for conf in "$SCRIPT_DIR/netdata/health.d/"*.conf; do
    scp "$conf" root@"$VPS_IP":"$CONFIG_VOL/health.d/$(basename $conf)"
    log "  health.d/$(basename $conf)"
done

# Notificaties kopiëren en SMTP wachtwoord invullen
echo "→ Notificatieconfig kopiëren..."
if [[ -n "$SMTP_PASSWORD" ]]; then
    sed "s/VERVANG_MET_APP_WACHTWOORD/${SMTP_PASSWORD}/" \
        "$SCRIPT_DIR/netdata/health_alarm_notify.conf" | \
        ssh root@"$VPS_IP" "cat > $CONFIG_VOL/health_alarm_notify.conf"
    log "health_alarm_notify.conf gekopieerd (met SMTP wachtwoord)"

    # msmtprc aanmaken voor msmtp (gebruikt door Netdata als sendmail)
    ssh root@"$VPS_IP" "cat > $CONFIG_VOL/msmtprc << EOF
defaults
auth           on
tls            on
tls_trust_file /etc/ssl/certs/ca-certificates.crt
logfile        /var/log/netdata/msmtp.log

account        default
host           smtp.hostinger.com
port           587
from           info@workinglocal.be
user           info@workinglocal.be
password       ${SMTP_PASSWORD}
EOF
chmod 600 $CONFIG_VOL/msmtprc"
    log "msmtprc aangemaakt (persistent in volume)"
else
    scp "$SCRIPT_DIR/netdata/health_alarm_notify.conf" \
        root@"$VPS_IP":"$CONFIG_VOL/health_alarm_notify.conf"
    warn "health_alarm_notify.conf gekopieerd ZONDER SMTP wachtwoord"
    warn "Stel het in via: bash deploy-config.sh $VPS_IP --smtp-password <wachtwoord>"
fi

# Netdata herstarten
echo "→ Netdata herstarten..."
ssh root@"$VPS_IP" "docker restart $NETDATA" > /dev/null
ssh root@"$VPS_IP" "docker inspect $NETDATA --format '{{.State.Status}}'"
log "Netdata herstart"

echo ""
log "Configuratie gedeployd. Controleer alerts via https://metrics.workinglocal.be"
