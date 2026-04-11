# Netdata Monitoring — Working Local

## Overzicht

Netdata draait als Docker container op VPS-WORKINGLOCAL, beheerd via Coolify.

- **URL:** `metrics.workinglocal.be`
- **Interne poort:** `19999`
- **DNS:** A-record direct naar VPS (geen Cloudflare proxy)

## Wat wordt gemonitord

- CPU gebruik en I/O wait
- RAM en swap gebruik
- Schijfruimte en disk I/O utilization
- Netwerkerrrors en pakket drops
- Docker container status en geheugen per container
- Load average, actieve processen, server uptime

Zie [alerts.md](alerts.md) voor alle drempelwaarden.

## 1. Eerste installatie via Coolify

1. In Coolify: **New Resource → Docker Compose**
2. Plak de inhoud van `docker-compose.yml` uit deze repo
3. Stel het domein in: `metrics.workinglocal.be` → poort `19999`
4. Deploy

Coolify regelt automatisch SSL via Caddy.

## 2. DNS instellen (Cloudflare)

```
Type:  A
Name:  metrics
Value: 23.94.220.181
TTL:   Auto
Proxy: DNS only (grijs wolkje — GEEN oranje wolk)
```

> Cloudflare proxy moet UIT staan: Netdata gebruikt WebSockets voor live updates.

## 3. Configuratie deployen

Na de eerste Coolify-deployment, deploy de config met het deploy-script.
Het script vereist SSH toegang als root naar de VPS.

```bash
# Zonder SMTP wachtwoord (alerts geconfigureerd maar geen e-mails)
bash deploy-config.sh

# Met SMTP wachtwoord — e-mailnotificaties worden ingeschakeld
bash deploy-config.sh 23.94.220.181 --smtp-password <app-wachtwoord>
```

Het script:
1. Zoekt de Netdata container en het config volume op de VPS
2. Kopieert `netdata/netdata.conf` naar het volume
3. Kopieert alle `netdata/health.d/*.conf` alerts
4. Kopieert `netdata/health_alarm_notify.conf` (met SMTP wachtwoord ingevuld)
5. Maakt `msmtprc` aan in het persistente config volume
6. Herstart de Netdata container

## 4. E-mailnotificaties (Hostinger SMTP)

Netdata gebruikt intern `msmtp` als sendmail-vervanging. De SMTP-configuratie:

| Instelling | Waarde |
|---|---|
| SMTP server | `smtp.hostinger.com` |
| Poort | `587` (STARTTLS) |
| Afzender | `info@workinglocal.be` |
| Ontvanger | `thomas@workinglocal.be` |

**Hoe het werkt:**
- `msmtprc` wordt opgeslagen in het persistente Netdata config volume (`/etc/netdata/msmtprc`)
- Bij elke container start kopieert de entrypoint het naar `/root/.msmtprc`
- Zo blijft de SMTP-config bewaard na container restarts en updates

**Wachtwoord wijzigen:**
```bash
bash deploy-config.sh 23.94.220.181 --smtp-password <nieuw-wachtwoord>
```

Het SMTP-wachtwoord staat **nooit** in de Git repo. `health_alarm_notify.conf` bevat de placeholder `VERVANG_MET_APP_WACHTWOORD`.

## 5. Alerts testen

Test of e-mailnotificaties werken door vanuit de Netdata container een test te sturen:

```bash
# In de Netdata container
docker exec -it <netdata-container> bash
/usr/libexec/netdata/plugins.d/alarm-notify.sh test
```

Of controleer de Netdata logs:
```bash
docker logs <netdata-container> 2>&1 | grep -i "alarm\|smtp\|msmtp"
```

## 6. Config aanpassen

Alle configuratie staat in de `netdata/` map van deze repo. Workflow:

1. Pas de `.conf` bestanden aan lokaal
2. Commit en push naar GitHub
3. Run `bash deploy-config.sh` om naar de VPS te deployen

## Beveiliging

Netdata is standaard open. Beveilig via Coolify:
- **Optie 1:** Basic auth instellen in Coolify domein instellingen
- **Optie 2:** IP-restrictie via Caddy
- **Optie 3:** Netdata Cloud koppelen met claim token (zie `.env.template`)

## Temperatuurmeting

Op een KVM VPS zijn hardware temperatuursensoren **niet beschikbaar** — de hypervisor verbergt deze.
Temperatuurmonitoring is enkel mogelijk op bare metal servers met IPMI toegang.
