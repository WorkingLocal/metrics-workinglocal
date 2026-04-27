# Alert regels — Metrics Stack

Alerts worden gedefinieerd in `alert.rules.yml` en verwerkt door Prometheus + Alertmanager.

## Prometheus alert regels

| Alert | Expressie | Drempel | Duur | Ernst |
|-------|-----------|---------|------|-------|
| `InstanceDown` | `up == 0` | host niet bereikbaar | 2 min | critical |
| `HighCpuUsage` | CPU idle berekening | >80% | 5 min | warning |
| `HighMemoryUsage` | RAM beschikbaar vs totaal | >80% | 5 min | warning |
| `NvmeDiskUsageHigh` | `/dev/nvme*` gebruik | >80% | 5 min | warning |
| `NvmeDiskUsageCritical` | `/dev/nvme*` gebruik | >90% | 1 min | critical |

**NVMe filter:** disk alerts enkel op `/dev/nvme*` devices — geen Docker overlay, tmpfs of virtuele partities.

## Alertmanager routing

```
Alle alerts
├── severity=critical → email-critical
│     group_wait: 30s | group_interval: 5m | repeat: 1h
└── severity=warning  → email-warning (default)
      group_wait: 2m  | group_interval: 10m | repeat: 12h
```

Grouping: `[alertname, instance]` → één mail per host per alerttype.

**Inhibit rule:** als een critical actief is op een host, worden warnings voor diezelfde host onderdrukt.

## Mail subject formaat

| Ernst | Subject |
|-------|---------|
| Warning | `[WARNING] HighCpuUsage — VM-AUTOBA` |
| Critical | `[CRITICAL] InstanceDown — NUT-SERVER` |
| Resolved | zelfde subject, body vermeldt "RESOLVED" |

## SMTP configuratie

| Instelling | Waarde |
|-----------|--------|
| Server | smtp.hostinger.com:587 (STARTTLS) |
| Afzender | info@workinglocal.be |
| Ontvanger | thomas@workinglocal.be |
| Wachtwoord | in `.env` op VPS (`SMTP_PASSWORD`) |

## Drempelwaarden aanpassen

Bewerk `alert.rules.yml` en deploy:

```bash
bash deploy-config.sh --smtp-password <wachtwoord>
```

Prometheus herlaadt regels via `POST /-/reload` (geen herstart nodig).
Alertmanager vereist wel een herstart: `docker restart alertmanager-metrics`.
