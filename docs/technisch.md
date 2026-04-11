# Technische documentatie — Netdata Monitoring Working Local

## Concept

Netdata draait als Docker container op de VPS en monitort alle systeembronnen en Docker containers in real-time. E-mailmeldingen worden verstuurd via Hostinger SMTP wanneer drempelwaarden overschreden worden.

## Architectuur

```
VPS-WORKINGLOCAL
    │
    ├── netdata container
    │   ├── System metrics (CPU, RAM, disk, netwerk)
    │   ├── Docker metrics (alle containers)
    │   ├── Health alerts (drempelwaarden bewaken)
    │   └── msmtp (interne SMTP client)
    │       └── smtp.hostinger.com:587
    │           └── → thomas@workinglocal.be
    │
    └── Traefik → metrics.workinglocal.be
```

## docker-compose.yml

```yaml
services:
  netdata:
    image: netdata/netdata:latest
    pid: host
    cap_add: [SYS_PTRACE, SYS_ADMIN]
    security_opt: [apparmor:unconfined]
    volumes:
      - netdataconfig:/etc/netdata      # configuratie (persistent)
      - netdatalib:/var/lib/netdata     # opgeslagen data
      - netdatacache:/var/cache/netdata
      - /proc:/host/proc:ro             # systeem metrics
      - /sys:/host/sys:ro
      - /var/run/docker.sock:ro         # Docker metrics
    entrypoint: >
      sh -c "
        if [ -f /etc/netdata/msmtprc ]; then
          cp /etc/netdata/msmtprc /root/.msmtprc;
        fi &&
        exec /usr/sbin/netdata -D"
```

## Configuratiebestanden

Alle config staat in de `netdata/` map van de repo en wordt uitgerold via `deploy-config.sh`.

| Bestand | Inhoud |
|---|---|
| `netdata/netdata.conf` | Hostname, data retentie, health instellingen |
| `netdata/health_alarm_notify.conf` | E-mail SMTP configuratie |
| `netdata/health.d/cpu.conf` | CPU alerts |
| `netdata/health.d/memory.conf` | RAM en swap alerts |
| `netdata/health.d/disk.conf` | Schijfruimte en I/O alerts |
| `netdata/health.d/network.conf` | Netwerk errors en drops |
| `netdata/health.d/docker.conf` | Container status en geheugen |
| `netdata/health.d/system.conf` | Load average, processen, uptime |

## Health alerts

| Categorie | Alert | Warn | Crit |
|---|---|---|---|
| CPU | `cpu_usage_warning` | >75% | >90% |
| CPU | `cpu_iowait_warning` | >20% | >40% |
| RAM | `ram_usage_warning` | >80% | >90% |
| Swap | `swap_usage_warning` | >50% | >80% |
| Disk | `disk_space_root_warning` | >75% | >90% |
| Disk | `disk_utilization_warning` | >80% | >95% |
| Netwerk | `net_errors_warning` | >10/s | >100/s |
| Docker | `docker_container_running` | — | gestopt |
| Docker | `docker_container_mem_warning` | >1.5 GB | >2 GB |
| Systeem | `load_average_warning` | >6 | >12 |
| Systeem | `reboot_required` | uptime <5m | — |

## SMTP configuratie (msmtp)

Netdata v2 gebruikt `msmtp` intern als sendmail-vervanging. De configuratie wordt persistent opgeslagen in het Docker volume zodat ze bewaard blijft na container restarts.

| Instelling | Waarde |
|---|---|
| SMTP server | `smtp.hostinger.com` |
| Poort | `587` (STARTTLS) |
| Afzender | `info@workinglocal.be` |
| Ontvanger | `thomas@workinglocal.be` |
| Configuratiebestand | `/etc/netdata/msmtprc` (in volume) |

**Persistentie-mechanisme:**
1. `deploy-config.sh` schrijft `msmtprc` naar `/etc/netdata/msmtprc` (in het persistente volume)
2. De container entrypoint kopieert dit bij elke start naar `/root/.msmtprc`
3. Netdata roept `msmtp` aan als sendmail

## Temperatuurmeting

Op een KVM VPS zijn hardware temperatuursensoren niet beschikbaar — de hypervisor verbergt deze. Temperatuurmonitoring is enkel mogelijk op bare metal servers met IPMI toegang.

## deploy-config.sh

Het script voert volgende stappen uit op de VPS:
1. Netdata container naam ophalen via `docker ps`
2. Config volume pad ophalen via `docker inspect`
3. Configuratiebestanden kopiëren via `scp`
4. `msmtprc` aanmaken met SMTP wachtwoord
5. Netdata container herstarten

## Data retentie

| Periode | Resolutie |
|---|---|
| 30 dagen | Per seconde |
| 6 maanden | Per minuut |
| 2 jaar | Per uur |
