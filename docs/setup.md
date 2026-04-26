# Setup handleiding — Metrics Stack

## Stack overzicht

| Container | Rol | Netwerk |
|-----------|-----|---------|
| `prometheus-metrics` | Metrics scrapen van alle nodes | `host` (voor Tailscale toegang) |
| `grafana-metrics` | Dashboards | `monitoring` + Traefik netwerk |
| `alertmanager-metrics` | E-mail alerts | `monitoring` |
| `uptime-kuma-metrics` | URL/port uptime | `monitoring` + Traefik netwerk |

## VPS locatie

```
/data/coolify/services/metrics-stack/
├── docker-compose.yml
├── prometheus.yml
├── alert.rules.yml
├── alertmanager.yml
├── .env                    # GRAFANA_ADMIN_PASSWORD + SMTP_PASSWORD
└── grafana/
    └── provisioning/
        ├── datasources/prometheus.yml
        └── dashboards/dashboards.yml
```

## Credentials

| Service | Gebruiker | Wachtwoord |
|---------|-----------|-----------|
| Grafana | admin | zie `.env` op VPS |
| Uptime Kuma | admin | zelfde als Grafana |
| Prometheus | — | geen auth (intern) |
| Alertmanager | — | geen auth (intern) |

## Eerste installatie

### 1. Bestanden deployen

```bash
# Vanuit de metrics-workinglocal repo:
bash deploy.sh --smtp-password <hostinger-wachtwoord>
```

### 2. .env aanmaken op VPS

```bash
ssh root@23.94.220.181
cat > /data/coolify/services/metrics-stack/.env << EOF
GRAFANA_ADMIN_PASSWORD=<sterk-wachtwoord>
SMTP_PASSWORD=<hostinger-smtp-wachtwoord>
EOF
```

### 3. Stack starten

```bash
cd /data/coolify/services/metrics-stack
docker compose up -d
```

### 4. node_exporter op VPS installeren

```bash
# Als root op VPS:
curl -sL https://raw.githubusercontent.com/WorkingLocal/metrics-workinglocal/main/install-node-exporter.sh | bash
```

### 5. Grafana dashboards importeren

Geïmporteerde dashboards (via API):
- **Node Exporter Full** (ID 1860) — Linux node metrics
- **Windows Exporter Dashboard** (ID 14694) — Windows Server metrics

Via Grafana UI: Dashboards → Import → ID invoeren.

## node_exporter op Linux nodes installeren

```bash
# SSH naar de node en uitvoeren als root:
curl -sL https://raw.githubusercontent.com/WorkingLocal/metrics-workinglocal/main/install-node-exporter.sh | bash
```

Getest op: Ubuntu, Debian, Raspberry Pi OS (auto-detectie van arch: amd64/arm64/armv7).

## windows_exporter op Windows Server

1. Download MSI van https://github.com/prometheus-community/windows_exporter/releases
2. Installeer: `msiexec /i windows_exporter-*.msi /quiet ENABLED_COLLECTORS=cpu,cs,logical_disk,net,os,service,system,memory`
3. Default luistert op poort 9182

## Prometheus targets verifiëren

```bash
ssh root@23.94.220.181
curl -s http://localhost:9090/api/v1/targets | python3 -c "
import json,sys
d=json.load(sys.stdin)
for t in d['data']['activeTargets']:
    print(t['health'], t['labels']['job'], t['labels']['instance'])
"
```

## DNS vereisten

| Record | Waarde |
|--------|--------|
| metrics.workinglocal.be | A → 23.94.220.181 |
| uptime.workinglocal.be | A → 23.94.220.181 (nog aan te maken in Cloudflare) |

## Bekende beperkingen

| Node | Status | Reden |
|------|--------|-------|
| NUT-SERVER Pi (100.97.195.23) | Prometheus: down | Geen SSH-toegang voor installatie node_exporter |
| VM-AI-Engine (100.80.180.55) | Prometheus: down | Ubuntu nog niet geïnstalleerd op VM |
