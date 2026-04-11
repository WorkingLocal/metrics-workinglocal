# Hoe gebruik ik Netdata? — Working Local

## Wat is dit?

Netdata bewaakt de VPS en stuurt e-mailmeldingen als er iets misgaat — hoge CPU, weinig schijfruimte, containers die stoppen, enzovoort. Je kan ook live meekijken via de webinterface.

---

## Hoe bekijk ik de live metrics?

Ga naar **https://metrics.workinglocal.be**

Je ziet real-time grafieken van:
- CPU gebruik per core
- RAM en swap gebruik
- Schijfruimte en I/O
- Netwerk verkeer
- Alle Docker containers

---

## Hoe deploy ik Netdata op de VPS?

### Stap 1 — Deployen via Coolify

1. Ga naar **https://coolify.workinglocal.be**
2. Klik **New Resource → Docker Compose**
3. Plak de inhoud van `docker-compose.yml` uit deze repo
4. Domein instellen: `https://metrics.workinglocal.be` → poort `19999`
5. Klik **Deploy**

### Stap 2 — DNS instellen

Voeg een A-record toe in Cloudflare:
- **Type:** A
- **Naam:** metrics
- **Waarde:** VPS-IP
- **Proxy:** UIT (grijs wolkje) — Netdata gebruikt WebSockets

### Stap 3 — Configuratie en e-mailmeldingen instellen

Op je laptop, in de map van deze repo:

```bash
bash deploy-config.sh 23.94.220.181 --smtp-password <jouw-smtp-wachtwoord>
```

Het SMTP-wachtwoord is het app-wachtwoord van het Hostinger e-mailaccount `info@workinglocal.be`.

Na dit commando:
- Worden alle alert-configuraties gekopieerd naar de VPS
- Wordt het SMTP-wachtwoord veilig opgeslagen in het Docker volume
- Wordt Netdata herstart

---

## Hoe weet ik of e-mailmeldingen werken?

Test de meldingen vanuit de container:

```bash
ssh root@23.94.220.181
docker exec -it <netdata-container> bash
/usr/libexec/netdata/plugins.d/alarm-notify.sh test
```

Je ontvangt een test-e-mail op `thomas@workinglocal.be`.

Of bekijk de logs:

```bash
docker logs <netdata-container> 2>&1 | grep -i "alarm\|smtp\|msmtp" | tail -20
```

---

## Hoe pas ik drempelwaarden aan?

De drempelwaarden staan in de bestanden in `netdata/health.d/`. Open het betreffende bestand en pas de waarden aan.

Voorbeeld — CPU limiet verhogen naar 85%:

```
# netdata/health.d/cpu.conf
warn: $this > 85    # was 75
crit: $this > 95    # was 90
```

Daarna deployen:

```bash
bash deploy-config.sh 23.94.220.181
```

Zie [alerts.md](alerts.md) voor een overzicht van alle geconfigureerde alerts.

---

## Hoe wijzig ik het SMTP-wachtwoord?

```bash
bash deploy-config.sh 23.94.220.181 --smtp-password <nieuw-wachtwoord>
```

Het nieuwe wachtwoord wordt opgeslagen in het persistente Docker volume en blijft bewaard na herstart.

---

## Hoe voeg ik een nieuwe alert toe?

1. Maak of bewerk een `.conf` bestand in `netdata/health.d/`
2. Volg de Netdata alarm syntax:

```
alarm: mijn_alert_naam
   on: system.cpu
 calc: $user + $system
 warn: $this > 80
 crit: $this > 95
 info: CPU gebruik te hoog
   to: sysadmin
```

3. Deploy:

```bash
bash deploy-config.sh 23.94.220.181
```

---

## Problemen oplossen

| Probleem | Oplossing |
|---|---|
| Dashboard niet bereikbaar | Controleer DNS: `dig metrics.workinglocal.be +short` |
| Geen e-mailmeldingen | Test via `alarm-notify.sh test` en bekijk de logs |
| SMTP fout | Controleer of msmtprc aanwezig is: `docker exec <container> cat /root/.msmtprc` |
| Container start niet | `docker logs <netdata-container>` voor foutmeldingen |
| Temperatuur niet zichtbaar | Niet beschikbaar op KVM VPS — alleen op bare metal hardware |
