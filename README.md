# Munin (master)

## Quickstart

Munin stats aggregator and reporting, based on lrivallain (<https://github.com/lrivallain)> and Arcus (<http://arcus.io)> work.
Update base image (ubuntu 24.04) and munin (2.0.75) and add easily configurable mail and Slack notifications.

### Build

```bash
git clone git@github.com:ethersys/ethersys-docker-munin.git
docker build -t munin ./
docker run -p 80 munin
```

### Or pull

```bash
docker pull ghcr.io/ethersys/munin
docker run -p 80 ghcr.io/ethersys/munin:latest
```

## How it works

### Ports

- 80 (configurable via environment variable `LISTENPORT`)

### Volumes

- `/var/lib/munin` : Databases files
- `/var/log/munin` : Logs
- `/var/cache/munin` : Where are generated graphs

### Environment Variables

- `NODES`: Space separated list of `<name>:<host>` munin node pairs. (i.e. `foo.local:127.0.0.1 bar.remote:1.2.3.4`)
- `CRONDELAY`: Change the cron settings to update charts every X minutes (default: 5)
- `TZ`: Customize the timezone according to your place: (i.e. `Europe/London`) (default: `Europe/Paris`)
- `THISNODENAME`: Customize the displayed node name for local host (default: `munin`)
- `THISNODEIP`: Customize the node IP for local host (default: `127.0.0.1`)
- `DISABLELOCALNODE`: Disable local munin node (default: `no`)
- `LISTENPORT`: The port in which Apache will listen on (default: `80`)
- `MAILCONTACT`: Recipient of the mail alert (i.e. `alert@example.test`, needed for mail alert)
- `MAILSERVER`: Address of your mail server (i.e. `mail.example.test`, needed for mail alert)
- `MAILPORT`: Port of your SMTP mail server  (i.e. `25`, needed for mail alert)
- `MAILUSER`: User to Auth on your mail server  (i.e. `user@example.test`, needed for mail alert)
- `MAILPASSWORD`: Password of your mail server (needed for mail alert)
- `MAILFROM`: Where the mail seems to come from (i.e. `munin@example.test`, needed for mail alert)
- `MAILDOMAIN`: Domain of your mail server (i.e. `example.test`, needed for mail alert)
- `MAILSTARTTLS`: Enable STARTTLS for email (default: `on`)
- `MAILTLS`: Enable TLS for email (default: `off`)
- `SLACKCHANNEL`: Name of your Slack channel (i.e. `hosting`, needed for Slack alert)
- `SLACKWEBHOOKURL`: URL of your Slack webhook (i.e. `https://hooks.slack.com/services/XXXXX/YYYYYYY/ZZZZZZZ`, needed for Slack alert)
- `SLACKUSER`: Username of munin bot on your Slack
- `SLACKICON`: Icon of munin bot on your Slack
- `VIRTUAL_HOST`: FQDN of your munin website (needed for Slack alert)

## Persistent example

```bash
docker run \
 -d \
 --name=munin \
 -p 127.0.0.1:8080:80 \
 -e THISNODENAME="munin.example.com" \
 -e TZ="Europe/London" \
 -e CRONDELAY=2 \
 -e NODES="anothernode.example.com:1.2.3.4 anothernode2.example.com:5.6.7.8" \
 -v /data/munin/db:/var/lib/munin \
 -v /data/munin/logs:/var/log/munin \
 -v /data/munin/cache:/var/cache/munin \
 ghcr.io/ethersys/munin
```
