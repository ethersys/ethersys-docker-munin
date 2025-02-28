#!/bin/bash

# timezone settings
TZ=${TZ:="Europe/Paris"}
echo $TZ > /etc/timezone
# workaround https://bugs.launchpad.net/ubuntu/+source/tzdata/+bug/1554806
rm /etc/localtime
dpkg-reconfigure -f noninteractive tzdata

# change cron setting for updates
CRONDELAY=${CRONDELAY:=5}
sed -i "s/\*\/5/\*\/$CRONDELAY/g" /etc/cron.d/munin

# configure default node name
THISNODENAME=${THISNODENAME:="munin"}
sed -i "s/^\[localhost\.localdomain\]/\[$THISNODENAME\]/g" /etc/munin/munin.conf

# configure default node IP
THISNODEIP=${THISNODEIP:="127.0.0.1"}
sed -i "s/^\( *address\) 127\.0\.0\.1\$/\1 $THISNODEIP/" /etc/munin/munin.conf

# configure default servername
THISSERVERNAME=${SERVERNAME:="munin"}
sed -i "s/^\[localhost\.localdomain\]/\[$SERVERNAME\]/g" /etc/apache2/sites-available/000-default.conf

if [[ $DISABLELOCALNODE == "yes" ]] ; then
  echo "includedir /etc/munin/munin-conf.d" > /etc/munin/munin.conf
fi

# configure apache port
LISTENPORT=${LISTENPORT:="80"}
sed -i "s/Listen 80/Listen $LISTENPORT/g" /etc/apache2/ports.conf

# configure mail notification

if [[ -n "$MAILCONTACT" && -n "$MAILSERVER" && -n "$MAILPORT" && -n "$MAILUSER" && -n "$MAILPASSWORD" && -n "$MAILDOMAIN" ]] ; then
  MAILCONTACT=${MAILCONTACT:="contact@domain.test"}
  sed -i "s/mailcontact/$MAILCONTACT/g" /etc/msmtprc
  sed -i "s/mailcontact/$MAILCONTACT/g" /etc/munin/munin-conf.d/munin_mail.conf
  MAILSERVER=${MAILSERVER:="mail.domain.test"}
  sed -i "s/mailserver/$MAILSERVER/g" /etc/msmtprc
  MAILPORT=${MAILPORT:="25"}
  sed -i "s/mailport/$MAILPORT/g" /etc/msmtprc
  MAILUSER=${MAILUSER:="munin@domain.test"}
  sed -i "s/mailuser/$MAILUSER/g" /etc/msmtprc
  MAILPASSWORD=${MAILPASSWORD:="XXXXXXXXX"}
  sed -i "s/mailpassword/$MAILPASSWORD/g" /etc/msmtprc
  MAILFROM=${MAILFROM:=$MAILUSER}
  sed -i "s/mailfrom/$MAILFROM/g" /etc/msmtprc
  sed -i "s/mailfrom/$MAILFROM/g" /etc/munin/munin-conf.d/munin_mail.conf
  MAILDOMAIN=${MAILDOMAIN:="domain.test"}
  sed -i "s/maildomain/$MAILDOMAIN/g" /etc/msmtprc
  MAILNAME=${MAILNAME:="Munin"}
  sed -i "s/munin application user/$MAILNAME/g" /etc/passwd
  MAILTLS=${MAILTLS:="off"}
  sed -i "s/mailtls/$MAILTLS/g" /etc/msmtprc
  MAILSTARTTLS=${MAILSTARTTLS:="on"}
  sed -i "s/mailstarttls/$MAILSTARTTLS/g" /etc/msmtprc
else
  rm /etc/munin/munin-conf.d/munin_mail.conf /etc/ssmtp/ssmtp.conf
fi

# configure Slack notification

if [[ -n "$SLACKCHANNEL" && -n "$SLACKWEBHOOKURL" ]] ; then
  SLACKCHANNEL=${SLACKCHANNEL:="hosting"}
  sed -i "s/slackchannel/$SLACKCHANNEL/g" /usr/local/bin/notify_slack_munin
  SLACKWEBHOOKURL=${SLACKWEBHOOKURL:="https://hooks.slack.com/services/XXXXX/YYYYYYY/ZZZZZZZ"}
  sed -i "s,slackwebhookurl,$SLACKWEBHOOKURL,g" /usr/local/bin/notify_slack_munin
  SLACKUSER=${SLACKUSER:="munin"}
  sed -i "s/slackuser/$SLACKUSER/g" /usr/local/bin/notify_slack_munin
  SLACKICON=${SLACKICON:=":bomb:"}
  sed -i "s/slackicon/$SLACKICON/g" /usr/local/bin/notify_slack_munin
  sed -i "s/muninurl/$VIRTUAL_HOST/g" /usr/local/bin/notify_slack_munin
  sed -i "s/muninurl/$VIRTUAL_HOST/g" /etc/munin/munin-conf.d/munin_slack.conf
else
  rm /etc/munin/munin-conf.d/munin_slack.conf
fi

# generate node list
NODES=${NODES:-}
for NODE in $NODES
do
    NAME=`echo $NODE | cut -d ':' -f1`
    HOST=`echo $NODE | cut -d ':' -f2`
    grep -q "${HOST}$" /etc/munin/munin.conf || cat << EOF >> /etc/munin/munin.conf
[$NAME]
    address $HOST
    use_node_name yes

EOF
done

# placeholder html to prevent permission error
if [ ! -f /var/cache/munin/www/index.html ]; then
    cat << EOF > /var/cache/munin/www/index.html
<html>
  <head>
    <title>Munin</title>
  </head>
  <body>
    Munin has not run yet.  Please try again in a few moments.
  </body>
</html>
EOF
    chown -R munin: /var/cache/munin/www/index.html
fi

# ensure munin folder exist and have right permission

mkdir -p /var/lib/munin/cgi-tmp /var/cache/munin/www
chown -R munin:munin /var/lib/munin  /var/cache/munin
chmod -R ugo+rw /var/lib/munin/cgi-tmp

# start cron
/usr/sbin/cron &

# start local munin-node
/usr/sbin/munin-node > /dev/null 2>&1 &

# confirm nodes
echo "Using the following munin nodes:"
echo " $THISNODENAME"
echo " $NODES"

# start apache
/usr/sbin/apache2ctl start

# display logs
touch /var/log/munin/munin-update.log
chown munin:munin /var/log/munin/munin-update.log
tail -f /var/log/munin/munin-*.log
