To add Roundcube (a webmail client) to your Docker Mailserver setup, you'll need to add a new service to your `docker-compose.yml` file. Here's how you can modify your existing compose file to include Roundcube:

```yaml
services:
  # ... (your existing mailserver, reverse-proxy, and acme-companion services remain the same) ...
  roundcubedb:
    image: mysql:latest
    container_name: roundcubedb
    #    restart: unless-stopped
    volumes:
      - ./db/mysql:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=roundcube-mysql-pw
      - MYSQL_DATABASE=roundcubemail

  roundcubemail:
    image: roundcube/roundcubemail:latest
    container_name: roundcubemail
    #restart: unless-stopped
    hostname: roundcube.gitcoins.io
    depends_on:
      - roundcubedb
    links:
      - roundcubedb
    volumes:
      - ./www:/var/www/html
      - ./docker-data/roundcube/config/:/var/roundcube/config/:rw
    environment:
      #- ROUNDCUBEMAIL_DEFAULT_HOST=tls://mail.coinsgpt.io
      #- ROUNDCUBEMAIL_SMTP_SERVER=tls://mail.coinsgpt.io
      - VIRTUAL_HOST=roundcube.gitcoins.io
      - LETSENCRYPT_HOST=roundcube.gitcoins.io
      - ROUNDCUBEMAIL_DB_TYPE=mysql
      - ROUNDCUBEMAIL_DB_HOST=roundcubedb
      - ROUNDCUBEMAIL_DB_PASSWORD=roundcube-mysql-pw
      - ROUNDCUBEMAIL_SKIN=elastic
      - ROUNDCUBEMAIL_DEFAULT_HOST=ssl://mail.gitcoins.io
      - ROUNDCUBEMAIL_DEFAULT_PORT=993
      - ROUNDCUBEMAIL_SMTP_SERVER=tls://mail.gitcoins.io
      - ROUNDCUBEMAIL_SMTP_PORT=587
      - ROUNDCUBEMAIL_USERNAME_DOMAIN=gitcoins.io
      - ROUNDCUBEMAIL_INSTALL_PLUGINS=1

```

### Important Notes:

1. **Database**: The example uses SQLite for simplicity. For production, consider using MySQL/MariaDB (you'd need to add a database service).

2. **Virtual Host**: The `labels` section tells nginx-proxy to handle this container. Make sure:
   - You have a DNS record pointing `roundcube.gitcoins.io` to your server
   - The acme-companion will automatically get a certificate for it

3. **Configuration**: You might want to add more environment variables for customization:
   ```yaml
   environment:
     - ROUNDCUBEMAIL_PLUGINS=archive,zipdownload
     - ROUNDCUBEMAIL_SKIN=elastic
   ```
4. **Initial Setup**: After starting the container, you may need to complete the setup by visiting the web interface.

5. **Security**: Make sure to secure your Roundcube installation with strong passwords and keep it updated.
