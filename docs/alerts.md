# Netdata Alerts — Working Local

## Geconfigureerde alerts

### CPU (`health.d/cpu.conf`)

| Alert | Warn | Crit | Info |
|---|---|---|---|
| `cpu_usage_warning` | >75% | >90% | Totaal CPU gebruik (1 min gemiddelde) |
| `cpu_iowait_warning` | >20% | >40% | I/O wait — wijst op disk bottleneck |

### Memory (`health.d/memory.conf`)

| Alert | Warn | Crit | Info |
|---|---|---|---|
| `ram_usage_warning` | >80% | >90% | RAM gebruik |
| `swap_usage_warning` | >50% | >80% | Swap gebruik — RAM tekort |

### Disk (`health.d/disk.conf`)

| Alert | Warn | Crit | Info |
|---|---|---|---|
| `disk_space_root_warning` | >75% | >90% | Schijfruimte op `/` |
| `disk_space_docker_warning` | >75% | >90% | Docker schijfruimte |
| `disk_utilization_warning` | >80% | >95% | Disk I/O utilization |

### Netwerk (`health.d/network.conf`)

| Alert | Warn | Crit | Info |
|---|---|---|---|
| `net_errors_warning` | >10/s | >100/s | Netwerkerrrors op eth0 |
| `net_drops_warning` | >10/s | >50/s | Pakket drops op eth0 |

### Docker (`health.d/docker.conf`)

| Alert | Warn | Crit | Info |
|---|---|---|---|
| `docker_container_running` | — | gestopt | Container die zou moeten draaien is gestopt |
| `docker_container_mem_warning` | >1.5 GB | >2 GB | Geheugen per container |

### Systeem (`health.d/system.conf`)

| Alert | Warn | Crit | Info |
|---|---|---|---|
| `load_average_warning` | >6 | >12 | 15-min load average (6 cores) |
| `processes_too_many` | >500 | >1000 | Actieve processen |
| `reboot_required` | uptime <5m | — | Server recent herstart |

## Notificaties

Alerts worden verstuurd via e-mail (SMTP). Zie `netdata/health_alarm_notify.conf` voor de instellingen.

> Het SMTP wachtwoord staat **niet** in de repo. Stel het in via:
> ```bash
> bash deploy-config.sh <VPS-IP> --smtp-password <wachtwoord>
> ```

## Temperatuurmeting

Op een KVM VPS zijn hardware temperatuursensoren niet beschikbaar — de hypervisor verbergt deze. Temperatuurmonitoring is enkel mogelijk op bare metal servers met IPMI toegang.

## Configuratie deployen

```bash
# Alle config deployen (zonder SMTP wachtwoord)
bash deploy-config.sh

# Met SMTP wachtwoord instellen
bash deploy-config.sh 23.94.220.181 --smtp-password <app-wachtwoord>
```

## Drempelwaarden aanpassen

Pas de `.conf` bestanden aan in `netdata/health.d/` en run `deploy-config.sh` opnieuw.
Netdata herlaadt de config automatisch na een container restart.
