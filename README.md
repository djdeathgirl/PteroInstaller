# PteroInstaller
Unofficial script voor het installeren van het Panel & Daemon.

## Functies

- Automatische installatie van het Pterodactyl-paneel (afhankelijkheden, database, cronjob, nginx).
- Automatische installatie van de Pterodactyl daemon (Docker, NodeJS, systemd).
- Paneel: (optioneel) automatische configuratie van Let's Encrypt.
- Paneel: (optioneel) automatische configuratie van UFW (firewall voor Ubuntu / Debian)

## Supported installaties / OS.

Lijst van de Operating Systems die gesupport worden bij dit script.

### Supported panel operating systems and webservers

| Operating System  | Version | nginx support        | Apache support | PHP Version |
| ----------------- | ------- | -------------------- | -------------- | ----------- |
| Ubuntu            | 14.04   | :red_circle:         | :red_circle:   |             |
|                   | 16.04   | :white_check_mark:   | :red_circle:   | 7.2         |
|                   | 18.04   | :white_check_mark:   | :red_circle:   | 7.2         |
|                   | 20.04   | :red_circle:         | :red_circle:   |             |
| Debian            | 8       | :white_check_mark:   | :red_circle:   | 7.3         |
|                   | 9       | :white_check_mark:   | :red_circle:   | 7.3         |
|                   | 10      | :white_check_mark:   | :red_circle:   | 7.3         |
| CentOS            | 6       | :red_circle:         | :red_circle:   |             |
|                   | 7       | :white_check_mark:   | :red_circle:   | 7.3         |
|                   | 8       | :white_check_mark:   | :red_circle:   | 7.2         |

* Ubuntu 20.04 is onlangs uitgebracht en moet nog worden ondersteund, maar zal hopelijk binnenkort worden ondersteund. *

### Supported Daemon Operating systems

| Operating System  | Version | Supported            |
| ----------------- | ------- | -------------------- |
| Ubuntu            | 14.04   | :red_circle:         |
|                   | 16.04   | :white_check_mark:   |
|                   | 18.04   | :white_check_mark:   |
|                   | 20.04   | :red_circle:         |
| Debian            | 8       | :red_circle:         |
|                   | 9       | :white_check_mark:   |
|                   | 10      | :white_check_mark:   |
| CentOS            | 6       | :red_circle:         |
|                   | 7       | :white_check_mark:   |
|                   | 8       | :white_check_mark:   |

* Ubuntu 20.04 is onlangs uitgebracht en moet nog worden ondersteund, maar zal hopelijk binnenkort worden ondersteund. *

## Het gebruiken van het script.
Zodra je het script uitvoert krijg je een menu te zien met wat je wilt installeren, type 1, 2, of 3 naar je eigen keuze.

```bash
bash <(curl -s https://raw.githubusercontent.com/AspectDevelopment/PteroInstaller/master/Pterodactylscript.sh)
```

*Note: Op sommige systemen moet het al zijn aangemeld als root voordat het eenregelige commando wordt uitgevoerd.*

## Firewall setup

Het script configureerd je firwall niet, dit moet je handmatig doen!

### Debian/Ubuntu

Op Debian en Ubuntu kan `ufw` worden gebruikt. Installeer het met `apt`.

```bash
apt install -y ufw
```
#### Daemon

Accepteer poort 8080 en 2022.

```bash
ufw allow 8080
ufw allow 2022
```

#### Zet de firewall aan!

Zorg ervoor dat u ook SSH inschakelt (of SSH alleen vanaf uw IP toestaat, afhankelijk van uw configuratie).

```bash
ufw allow ssh
```

Zet de firewall aan.

```bash
ufw enable
```

### CentOS

Op CentOS, `firewall-cmd` Kan gebruikt worden.

#### Panel

Accepteer HTTP and HTTPS.

```bash
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
```

#### Daemon

Accepteer poort 8080 en 2022.

```bash
firewall-cmd --add-port 8080/tcp --permanent
firewall-cmd --add-port 2022/tcp --permanent
firewall-cmd --permanent --zone=trusted --change-interface=docker0
```

#### Zet de firewall aan!

Herlaad de firewall om verandering te brengen in het systeem.

```bash
firewall-cmd --reload
```
