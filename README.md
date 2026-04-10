# Metrics — Working Local

Netdata monitoring voor VPS-WORKINGLOCAL.

## Wat het doet

- **Systeemmonitoring** — CPU, RAM, disk, netwerk
- **Container metrics** — alle Docker containers op de VPS
- **Live dashboard** via `metrics.workinglocal.be`

## Deployment

Draait op `metrics.workinglocal.be` via Coolify op VPS-WORKINGLOCAL.

### Vereisten

- Coolify op de VPS (zie [vps-workinglocal](https://github.com/WorkingLocal/vps-workinglocal))
- DNS A-record: `metrics.workinglocal.be` → `23.94.220.181` (Cloudflare proxy UIT)

### Stappen

1. In Coolify: **New Resource → Docker Compose**
2. Plak de inhoud van `docker-compose.yml`
3. Domein instellen: `metrics.workinglocal.be` → poort `19999`
4. Deploy

Coolify regelt automatisch SSL via Caddy.

## Beveiliging

Netdata is standaard open. Beveilig via Coolify:

- **Basic auth** — instellen in de Coolify domeininstellingen
- **IP-restrictie** — via Caddy configuratie
- **Netdata Cloud** — koppelen met claim token (zie `.env.template`)

## Stack

| Onderdeel | Technologie |
|---|---|
| Monitoring | Netdata (laatste stabiele versie) |
| Reverse proxy | Caddy (via Coolify) |

## Documentatie

- [docs/setup.md](docs/setup.md) — volledige deployment handleiding

## Gerelateerde repositories

| Repo | Inhoud |
|---|---|
| [vps-workinglocal](https://github.com/WorkingLocal/vps-workinglocal) | Server setup & infrastructuur |
| [odoo-workinglocal](https://github.com/WorkingLocal/odoo-workinglocal) | Odoo CE + coworking addon |
| [signage-workinglocal](https://github.com/WorkingLocal/signage-workinglocal) | Xibo CMS voor digitale schermen |
| [focus-workinglocal](https://github.com/WorkingLocal/focus-workinglocal) | Focus Kiosk app |
