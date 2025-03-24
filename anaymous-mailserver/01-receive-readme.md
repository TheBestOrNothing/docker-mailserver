To configure your `gitcoins.io` domain to receive mail from other domains, you need to:

1. **Set Up DNS Records**  
   Configure the necessary DNS records (MX, A, PTR) for `gitcoins.io`.

2. **Update the `docker-compose.yml` File**  
   Modify the `hostname` and other settings in your `docker-compose.yml` to reflect your domain.

---

### 1. Configure DNS Records for `gitcoins.io`

You need to set up the following DNS records:

#### **MX Record**  
This tells mail servers where to deliver emails for `gitcoins.io`:

```
Type:  MX
Host:  @
Value: mail.gitcoins.io
Priority: 10
TTL: 3600
```

#### **A Record**  
Points `mail.gitcoins.io` to your server's public IP:

```
Type:  A
Host:  mail
Value: <YOUR_SERVER_IP>
TTL: 3600
```

#### **PTR Record (Reverse DNS)**
This must be configured at your hosting provider:

- Contact your hosting provider to set a reverse DNS (PTR) record for your server's IP, pointing to `mail.gitcoins.io`.

---

### 2. Modify `docker-compose.yml`

Update the `hostname` and ensure proper volume mounting:

```yaml
services:
  mailserver:
    image: ghcr.io/docker-mailserver/docker-mailserver:latest
    container_name: mailserver
    hostname: mail.gitcoins.io  # Update to match your domain
    domainname: gitcoins.io
    env_file: 00-original-mailserver.env
    ports:
      - "25:25"    # SMTP (for receiving emails)
      - "143:143"  # IMAP4 (STARTTLS)
      - "465:465"  # ESMTP (implicit TLS)
      - "587:587"  # ESMTP (explicit TLS)
      - "993:993"  # IMAP4 (implicit TLS)
    volumes:
      - ./docker-data/dms/mail-data/:/var/mail/
      - ./docker-data/dms/mail-state/:/var/mail-state/
      - ./docker-data/dms/mail-logs/:/var/log/mail/
      - ./docker-data/dms/config/:/tmp/docker-mailserver/
      - /etc/localtime:/etc/localtime:ro
    restart: always
    stop_grace_period: 1m
    healthcheck:
      test: "ss --listening --tcp | grep -P 'LISTEN.+:smtp' || exit 1"
      timeout: 3s
      retries: 0
```
---


### 3. Restart and Test

Restart the mail server:

```sh
docker compose  -f 01-receive-compose.yaml down
docker compose  -f 01-receive-compose.yaml up
docker ps
```

Send mail to alice@gitcoins.io

```
swaks --to alice@gitcoins.io --server mail.gitcoins.io --port 25
```

Test mail reception with:

```sh
telnet mail.gitcoins.io 25
```

Verify DKIM, SPF, and DMARC at:  
- [https://www.mail-tester.com/](https://www.mail-tester.com/)  
- [https://www.dmarcian.com/dkim-inspector/](https://www.dmarcian.com/dkim-inspector/)  

After these steps, your mail server should correctly receive emails for `gitcoins.io`. 🚀