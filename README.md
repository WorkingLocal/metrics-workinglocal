# Metrics — Working Local

Netdata monitoring voor VPS-WORKINGLOCAL.

## Wat het doet

- **Systeemmonitoring** — CPU, RAM, disk, netwerk, load average, processen
- **Container metrics** — alle Docker containers op de VPS (status + geheugen)
- **Health alerts** — e-mailmeldingen bij overschrijden van drempelwaarden
- **Live dashboard** via `metrics.workinglocal.be`

## Repositories structuur

```
metrics-workinglocal/
├── docker-compose.yml          # Netdata container definitie
├── deploy-config.sh            # Script om config naar VPS te deployen
├── netdata/
│   ├── netdata.conf            # Hoofdconfiguratie (hostname, retentie)
│   ├── health_alarm_notify.conf # E-mailnotificaties via Hostinger SMTP
│   └── health.d/               # Health alert definities
│       ├── cpu.conf
│       ├── memory.conf
│       ├── disk.conf
│       ├── network.conf
│       ├── docker.conf
│       └── system.conf
└── docs/
    ├── setup.md                # Volledige deployment handleiding
    └── alerts.md               # Overzicht van alle geconfigureerde alerts
```

## Deployment

Draait op `metrics.workinglocal.be` via Coolify op VPS-WORKINGLOCAL.

### Eerste installatie

1. In Coolify: **New Resource → Docker Compose**
2. Plak de inhoud van `docker-compose.yml`
3. Domein instellen: `metrics.workinglocal.be` → poort `19999`
4. Deploy

### Configuratie deployen

Na de eerste installatie, deploy de config inclusief alerts en SMTP:

```bash
# Zonder SMTP wachtwoord
bash deploy-config.sh

# Met SMTP wachtwoord (persistente opslag in Docker volume)
bash deploy-config.sh 23.94.220.181 --smtp-password <app-wachtwoord>
```

Het script kopieert alle config naar het Netdata config volume en herstart de container.

## Alerts

Alerts worden verstuurd via e-mail (`info@workinglocal.be` → `thomas@workinglocal.be`) via Hostinger SMTP.

Zie [docs/alerts.md](docs/alerts.md) voor een overzicht van alle geconfigureerde alerts.

## Vereisten

- Coolify op de VPS (zie [vps-workinglocal](https://github.com/WorkingLocal/vps-workinglocal))
- DNS A-record: `metrics.workinglocal.be` → `23.94.220.181` (Cloudflare proxy UIT)
- SSH toegang als root voor `deploy-config.sh`

## Beveiliging

Netdata is standaard open. Beveilig via Coolify:

- **Basic auth** — instellen in de Coolify domeininstellingen
- **IP-restrictie** — via Caddy configuratie
- **Netdata Cloud** — koppelen met claim token (zie `.env.template`)

## Stack

| Onderdeel | Technologie |
|---|---|
| Monitoring | Netdata (laatste stabiele versie) |
| E-mail | msmtp + Hostinger SMTP |
| Reverse proxy | Caddy (via Coolify) |

## Documentatie

- [docs/setup.md](docs/setup.md) — volledige deployment handleiding
- [docs/alerts.md](docs/alerts.md) — overzicht van alle health alerts

## Gerelateerde repositories

| Repo | Inhoud |
|---|---|
| [vps-workinglocal](https://github.com/WorkingLocal/vps-workinglocal) | Server setup & infrastructuur |
| [odoo-workinglocal](https://github.com/WorkingLocal/odoo-workinglocal) | Odoo CE + coworking addon |
| [signage-workinglocal](https://github.com/WorkingLocal/signage-workinglocal) | Xibo CMS voor digitale schermen |
| [focus-workinglocal](https://github.com/WorkingLocal/focus-workinglocal) | Focus Kiosk app |
