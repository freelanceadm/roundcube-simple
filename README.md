# roundcube-simple
Simple roundcube docker repo. 

This container use 3 images.
  forthex/roundcube
  forthex/dovecot
  mariadb:latest

### Roundcube container
This container is quite simple. It run dovecot and postfix.

Exposed ports:
  - 80

Container use '/var/vmail' directory to store users data.

Users info - login/pass stored in /etc/dovecot/users file.

Example of users file:
```
myfirstuser@example.com:{plain}myuserpassword
```

If you do not provide 'users' file it will create default user for testing perpose with name 'rcadmin@youmailservername.com' and password 'rcpass'.

Variables:
```
MHOSTNAME: "mail.example.com"
MLISTENON: "all"
```

MLISTENON - which interfaces to listen. Postfix 'inet_interfaces' variable. Default value 'all'.
MHOSTNAME - postfix 'virtual_mailbox_domains' value. Default 'example.com'.

### Dovecot container
 Exposed ports:
   - 143 ( imap )
   - 110 ( pop3 )
   -  25 ( smtp )

 Container use '/var/vmail' directory to store users data.

 Users info - login/pass stored in /etc/dovecot/users file.

 Example of users file:
   myfirstuser@example.com:{plain}myuserpassword

 If you do not provide 'users' file it will create default user for testing perpose with name 'rcadmin@youmailservername.com' and password 'rcpass'.

 Variables:
    MHOSTNAME: "mail.example.com"
    MLISTENON: "all"

    MLISTENON - which interfaces to listen. Postfix 'inet_interfaces' variable. Default value 'all'.
    MHOSTNAME - postfix 'virtual_mailbox_domains' value. Default 'example.com'.


### How to run
You can create '.env' file with variables and docker-compose.yml.

Here is '.env'
```
### Database container
MYSQL_ROOT_PASSWORD=sqlrootpass
MYSQL_DATABASE=roundcube
MYSQL_USER=rcubeuser
MYSQL_PASSWORD=DasIstEinPassword

### postfix and dovecot container
### use `hostname -f` as hostname
HOSTNAME=yourmailhostname
LISTENON=all

```
Here is 'docker-compose.yml'
```
version: '2'
services:
  web:
    restart: on-error
    build: ./myroundcube
    mem_limit: "512000000"
    image: forthex/roundcube
    ports:
        - "8081:80"
    environment:
        DBNAME: "${MYSQL_DATABASE}"
        DBUSR: "${MYSQL_USER}"
        DBUSRPASS: "${MYSQL_PASSWORD}"
        DBHOST: "mariadb"
        SMTPSERVER: "${HOSTNAME}"
    depends_on:
        - "mariadb"
        - "mypostfix"

  mypostfix:
    restart: on-error
    build: ./mydovecot
    image: forthex/dovecot
    mem_limit: 256m
    ports:
      - "25:25"
      - "110:110"
      - "143:143"
    environment:
      MHOSTNAME: "${HOSTNAME}"
      MLISTENON: "${LISTENON}"
    volumes:
      - ./data/vmail:/var/vmail
      - ./myusers:/etc/dovecot/users
    networks:
      default:
        aliases:
          - "${HOSTNAME}"

  mariadb:
    image: mariadb
    restart: always
    mem_limit: "512000000"
    expose:
        - 3306
    volumes:
        - ./data/mysql:/var/lib/mysql
    environment:
        - MYSQL_ROOT_PASSWORD
        - MYSQL_DATABASE
        - MYSQL_USER
        - MYSQL_PASSWORD
```
