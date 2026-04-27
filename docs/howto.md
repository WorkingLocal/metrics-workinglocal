# Hoe gebruik ik de monitoring stack? — Working Local

## Dashboards bekijken

**Grafana:** https://metrics.workinglocal.be
- Login: `admin` / zie `.env` op VPS
- Beschikbare dashboards: Node Exporter Full, Windows Exporter
- Selecteer een host via de `instance` dropdown bovenaan

**Uptime Kuma:** https://uptime.workinglocal.be
- Login: `admin` / zelfde wachtwoord als Grafana
- Publieke status page: https://uptime.workinglocal.be/status/hosting-local

---

## E-mailmeldingen

Alerts komen van `info@workinglocal.be` naar `thomas@workinglocal.be`.

**Subject formaat:**
- `[WARNING] HighCpuUsage — VM-AUTOBA`
- `[CRITICAL] InstanceDown — NUT-SERVER`

Warnings herhalen elke **12 uur** zolang het probleem aanhoudt.
Criticals herhalen elke **1 uur**.

---

## node_exporter installeren op een nieuwe Linux node

```bash
# SSH naar de node als root:
curl -sL https://raw.githubusercontent.com/WorkingLocal/metrics-workinglocal/main/install-node-exporter.sh | bash
```

Daarna toevoegen in `prometheus.yml`:

```yaml
- job_name: 'nieuwe-node'
  static_configs:
    - targets: ['<tailscale-ip>:9100']
      labels:
        instance: 'NIEUWE-NODE'
```

Deploy en herlaad:

```bash
scp prometheus.yml root@23.94.220.181:/data/coolify/services/metrics-stack/
ssh root@23.94.220.181 'curl -s -X POST http://localhost:9090/-/reload'
```

---

## windows_exporter installeren op Windows

1. Download MSI: https://github.com/prometheus-community/windows_exporter/releases
2. Installeer: `msiexec /i windows_exporter-*.msi /quiet ENABLED_COLLECTORS=cpu,cs,logical_disk,net,os,service,system,memory`
3. Poort 9182, bereikbaar via Tailscale
4. Voeg toe aan `prometheus.yml` met poort 9182

---

## Drempelwaarden aanpassen

Bewerk `alert.rules.yml` in de repo en deploy:

```bash
scp alert.rules.yml root@23.94.220.181:/data/coolify/services/metrics-stack/
ssh root@23.94.220.181 'curl -s -X POST http://localhost:9090/-/reload'
```

Zie [alerts.md](alerts.md) voor een overzicht van alle regels.

---

## Alertmanager routing aanpassen

Bewerk `alertmanager.yml` en herstart:

```bash
scp alertmanager.yml root@23.94.220.181:/data/coolify/services/metrics-stack/
ssh root@23.94.220.181 'docker restart alertmanager-metrics'
```

Of gebruik het deploy script (werkt ook SMTP wachtwoord bij):

```bash
bash deploy-config.sh --smtp-password <wachtwoord>
```

---

## SMTP wachtwoord bijwerken

```bash
bash deploy-config.sh --smtp-password <nieuw-wachtwoord>
```

---

## Grafana dashboard importeren

1. Ga naar Grafana → Dashboards → Import
2. Voer een dashboard ID in (bv. `1860` voor Node Exporter Full)
3. Selecteer datasource: `Prometheus`

---

## Problemen oplossen

| Probleem | Oplossing |
|----------|-----------|
| Host staat op "down" in Prometheus | `curl http://<tailscale-ip>:9100/metrics` — draait node_exporter? |
| Geen e-mailmeldingen | `docker logs alertmanager-metrics` — SMTP fout? |
| Grafana 504 fout | Grafana checkt intern via `http://grafana-metrics:3000/api/health` — Uptime Kuma mag niet de publieke URL gebruiken (hairpin NAT) |
| Prometheus regels niet geladen | `curl -s http://localhost:9090/api/v1/rules` op VPS |
