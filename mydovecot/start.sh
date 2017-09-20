#!/bin/bash

### setup config file for dovecot
# MHOSTNAME
# MLISTENON

[[ -z "MHOSTNAME" ]] && MHOSTNAME='example.com'
[[ -z "MLISTENON" ]] && MLISTENON='all'

# 1 setup main.cf
postpath='/etc/postfix/main.cf'

### add hostname
echo "myhostname = ${MHOSTNAME}" >> ${postpath}

sed -i -e 's/^inet_interfaces = localhost/inet_interfaces = '${MLISTENON}'/g' ${postpath}  
sed -i -e 's/#mynetworks_style = host/mynetworks_style = subnet/' ${postpath}

### add to main.cf
cat << EOF >> ${postpath}

### container added config
virtual_uid_maps = static:1000
virtual_gid_maps = static:1000
virtual_mailbox_domains = ${MHOSTNAME}
virtual_transport = dovecot

mydestination = localhost.$mydomain, localhost
EOF

### redirect mails via dovecot now
cat << EOF >> /etc/postfix/master.cf
dovecot   unix  -       n       n       -       -       pipe
  flags=DRhu user=vmail:vmail argv=/usr/libexec/dovecot/deliver -f \${sender} -d \${recipient}
EOF

### allow our vmail user acces to dovecot dir
chown -R .vmail /var/vmail
chmod -R g+rwXs /var/vmail

### if we did not mount 'users' file then we add by default
DEFADM='rcadmin'
DEFPASS='rcpass'
[[ -f /etc/dovecot/users ]] || echo "${DEFADM}@${MHOSTNAME}:{plain}${DEFPASS}" > /etc/dovecot/users

### run postfix
newaliases
postfix start
dovecot -F
