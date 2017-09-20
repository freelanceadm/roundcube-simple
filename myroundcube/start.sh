#!/bin/bash

### setup config file for roundcube using container variables
# DBHOST
# DBNAME
# DBUSR
# DBUSRPASS
# SMTPSERVER
DESKEY='ebb0fa6d69ad9a5b0e6930fd'

### set hostname: by default its localhost
[[ -z "SMTPSERVER" ]] && SMTPSERVER='localhost'

### init database for roundcube
while [ `mysqlshow -u${DBUSR} -p${DBUSRPASS} -h${DBHOST} ${DBNAME} | grep user | wc -l` -ne '1' ] 
do
  sleep 1
  echo 'Mysql is not up... Connecting...'

  ### only if it does not exist already
  CHECKDB=`mysqlshow -u${DBUSR} -p${DBUSRPASS} -h${DBHOST} ${DBNAME} | grep user | wc -l`
  if [ "${CHECKDB}" -eq "0" ]; then
    ### Database does ot exist
    cd /var/www/html/SQL
    echo "create database ${DBNAME};" | mysql --user=${DBUSR} --password=${DBUSRPASS} -h${DBHOST} ${DBNAME}
    mysql --user=${DBUSR} --password=${DBUSRPASS} -h${DBHOST} ${DBNAME} < mysql.initial.sql
  fi
done

### put config file for roundcube
cat << EOF > /var/www/html/config/config.inc.php
<?php

/* Local configuration for Roundcube Webmail */

// ----------------------------------
// SQL DATABASE
// ----------------------------------
// Database connection string (DSN) for read+write operations
// Format (compatible with PEAR MDB2): db_provider://user:password@host/database
// Currently supported db_providers: mysql, pgsql, sqlite, mssql or sqlsrv
// For examples see http://pear.php.net/manual/en/package.database.mdb2.intro-dsn.php
// NOTE: for SQLite use absolute path: 'sqlite:////full/path/to/sqlite.db?mode=0646'
\$config['db_dsnw'] = 'mysql://${DBUSR}:${DBUSRPASS}@${DBHOST}/${DBNAME}';

// ----------------------------------
// IMAP
// ----------------------------------
// The mail host chosen to perform the log-in.
// Leave blank to show a textbox at login, give a list of hosts
// to display a pulldown menu or set one host as string.
// To use SSL/TLS connection, enter hostname with prefix ssl:// or tls://
// Supported replacement variables:
// %n - hostname ($_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
// %s - domain name after the '@' from e-mail address provided at login screen
// For example %n = mail.domain.tld, %t = domain.tld
// WARNING: After hostname change update of mail_host column in users table is
//          required to match old user data records with the new host.
\$config['default_host'] = '${SMTPSERVER}';

// Auto add domain part to username durong login
\$config['username_domain'] = '%h';

// ----------------------------------
// SMTP
// ----------------------------------
// SMTP server host (for sending mails).
// To use SSL/TLS connection, enter hostname with prefix ssl:// or tls://
// If left blank, the PHP mail() function is used
// Supported replacement variables:
// %h - user's IMAP hostname
// %n - hostname ($_SERVER['SERVER_NAME'])
// %t - hostname without the first part
// %d - domain (http hostname $_SERVER['HTTP_HOST'] without the first part)
// %z - IMAP domain (IMAP hostname without the first part)
// For example %n = mail.domain.tld, %t = domain.tld
\$config['smtp_server'] = '${SMTPSERVER}';

// provide an URL where a user can get support for this Roundcube installation
// PLEASE DO NOT LINK TO THE ROUNDCUBE.NET WEBSITE HERE!
\$config['support_url'] = 'support-url';

// automatically create a new Roundcube user when log-in the first time.
// a new user will be created once the IMAP login succeeds.
// set to false if only registered users can use this service
\$config['auto_create_user'] = true;

// this key is used to encrypt the users imap password which is stored
// in the session record (and the client cookie if remember password is enabled).
// please provide a string of exactly 24 chars.
\$config['des_key'] = '${DESKEY}';

// Name your service. This is displayed on the login screen and in the window title
\$config['product_name'] = 'product-name';

// ----------------------------------
// PLUGINS
// ----------------------------------
// List of active plugins (in plugins/ directory)
\$config['plugins'] = array();

// store draft message is this mailbox
// leave blank if draft messages should not be stored
// NOTE: Use folder names with namespace prefix (INBOX. on Courier-IMAP)
\$config['drafts_mbox'] = 'Draftsmbox';

// store spam messages in this mailbox
// NOTE: Use folder names with namespace prefix (INBOX. on Courier-IMAP)
\$config['junk_mbox'] = 'Junkmbox';

// store sent message is this mailbox
// leave blank if sent messages should not be stored
// NOTE: Use folder names with namespace prefix (INBOX. on Courier-IMAP)
\$config['sent_mbox'] = 'Sentmbox';

// move messages to this folder when deleting them
// leave blank if they should be deleted directly
// NOTE: Use folder names with namespace prefix (INBOX. on Courier-IMAP)
\$config['trash_mbox'] = 'Trashmbox';

// Set the spell checking engine. Possible values:
// - 'googie'  - the default (also used for connecting to Nox Spell Server, see 'spellcheck_uri' setting)
// - 'pspell'  - requires the PHP Pspell module and aspell installed
// - 'enchant' - requires the PHP Enchant module
// - 'atd'     - install your own After the Deadline server or check with the people at http://www.afterthedeadline.com before using their API
// Since Google shut down their public spell checking service, the default settings
// connect to http://spell.roundcube.net which is a hosted service provided by Roundcube.
// You can connect to any other googie-compliant service by setting 'spellcheck_uri' accordingly.
\$config['spellcheck_engine'] = 'pspell';

?>
EOF

### fix dir permissions 
chown -R .apache /var/www/html/{logs,temp}
chmod g+rw /var/www/html/{logs,temp}

### at last enable web acces via running apache
/usr/sbin/httpd -DFOREGROUND
