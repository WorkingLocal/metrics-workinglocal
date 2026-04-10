# Netdata Monitoring — Working Local

## Overzicht

Netdata draait als Docker container op VPS-WORKINGLOCAL, beheerd via Coolify.

- **URL:** `metrics.workinglocal.be`
- **Interne poort:** `19999`
- **DNS:** A-record direct naar VPS (geen Cloudflare proxy)

## Deployment via Coolify

1. In Coolify: **New Resource → Docker Compose**
2. Plak de inhoud van `docker-compose.yml` uit deze repo
3. Stel het domein in: `metrics.workinglocal.be` → poort `19999`
4. Deploy

Coolify regelt automatisch SSL via Caddy.

## Wat wordt gemonitord

- CPU, RAM, disk, netwerk
- Docker container metrics (alle containers op de VPS)
- System processes

## Beveiliging

Netdata is standaard open. Beveilig via Coolify:
- **Optie 1:** Basic auth instellen in Coolify domein instellingen
- **Optie 2:** IP-restrictie via Caddy
- **Optie 3:** Netdata Cloud koppelen met claim token (zie `.env.template`)

## DNS instellen (Cloudflare)

```
Type:  A
Name:  metrics
Value: 23.94.220.181
TTL:   Auto
Proxy: DNS only (grijs wolkje)
```
