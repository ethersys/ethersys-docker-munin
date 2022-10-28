FROM ubuntu:22.04


LABEL org.opencontainers.image.authors="contact@ethersys.fr"
LABEL org.opencontainers.image.source="https://github.com/ethersys/ethersys-docker-munin"
LABEL org.opencontainers.image.description="Official Munin image with Docker binaries"

# install and configure munin
RUN apt-get update -qq && RUNLEVEL=1 DEBIAN_FRONTEND=noninteractive \
    apt-get install -y -qq cron munin nginx apache2 wget libapache2-mod-fcgid libcgi-fast-perl msmtp msmtp-mta mailutils curl tzdata autoconf
RUN (cp /etc/munin/apache24.conf /etc/apache2/sites-available/000-default.conf)
RUN (sed -i 's/^Alias.*/Alias \/ \/var\/cache\/munin\/www\//g' /etc/apache2/sites-available/000-default.conf)
RUN (sed -i 's/Allow from .*/Satisfy Any/g' /etc/apache2/sites-available/000-default.conf)
RUN (sed -i 's/Order allow,deny.*/Allow from all/g' /etc/apache2/sites-available/000-default.conf)
RUN (mkdir -p /var/run/munin && chown -R munin:munin /var/run/munin)

RUN (chfn -f 'munin' root)
RUN (/usr/sbin/a2enmod fcgid)

COPY 000-default.conf /etc/apache2/sites-available/000-default.conf
COPY logrotate-munin /etc/logrotate.d/munin
COPY munin.conf /etc/munin/munin.conf
COPY msmtprc /etc/msmtprc
COPY aliases /etc/aliases
COPY munin_mail.conf /etc/munin/munin-conf.d/munin_mail.conf
COPY slack_munin.sh /usr/local/bin/notify_slack_munin
RUN chmod +x /usr/local/bin/notify_slack_munin
COPY munin_slack.conf /etc/munin/munin-conf.d/munin_slack.conf

# copy launcher
ADD run.sh /usr/local/bin/run
RUN chmod +x /usr/local/bin/run

# persist
VOLUME /var/lib/munin
VOLUME /var/log/munin
VOLUME /var/cache/munin

EXPOSE 80

# launcher
CMD ["/usr/local/bin/run"]
