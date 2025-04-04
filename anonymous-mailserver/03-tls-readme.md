To enable **SSL/TLS** using `nginx-proxy` and `acme-companion` in your `docker-compose.yml`, you'll need to:

1. Add the `nginx-proxy` container
2. Add the `acme-companion` container
3. Configure Docker-Mailserver for Mailgun https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/mail-forwarding/relay-hosts/
4. Configure Docker-Mailserver for TLS https://docker-mailserver.github.io/docker-mailserver/latest/config/security/ssl/

However, note: **docker-mailserver handles its own mail TLS ports**, and reverse proxies (like Nginx) generally *don't* proxy mail protocols like SMTP or IMAP. If you only want to expose a **web interface** (e.g. for roundcute or admin access) via HTTPS, then Nginx is a good fit. But if you're specifically trying to enable SSL/TLS for your **mail protocols**, docker-mailserver already supports that (on ports like 465, 587, 993).

### That said, here's how to integrate with `nginx-proxy` and `acme-companion` to expose additional web services via HTTPS:

#### 1. Add `nginx-proxy` and `acme-companion` services
```yaml
services:
  mailserver:
    image: ghcr.io/docker-mailserver/docker-mailserver:latest
    container_name: mailserver
    # Provide the FQDN of your mail server here (Your DNS MX record should point to this value)
    hostname: mail.gitcoins.io
    env_file: 03-tls-mailserver.env
    # More information about the mail-server ports:
    # https://docker-mailserver.github.io/docker-mailserver/latest/config/security/understanding-the-ports/
    ports:
      - "25:25"    # SMTP  (explicit TLS => STARTTLS, Authentication is DISABLED => use port 465/587 instead)
      - "143:143"  # IMAP4 (explicit TLS => STARTTLS)
      - "465:465"  # ESMTP (implicit TLS)
      - "587:587"  # ESMTP (explicit TLS => STARTTLS)
      - "993:993"  # IMAP4 (implicit TLS)
    volumes:
      - ./docker-data/dms/mail-data/:/var/mail/
      - ./docker-data/dms/mail-state/:/var/mail-state/
      - ./docker-data/dms/mail-logs/:/var/log/mail/
      - ./docker-data/dms/config/:/tmp/docker-mailserver/
      - /etc/localtime:/etc/localtime:ro
      - ./docker-data/acme-companion/certs/:/etc/letsencrypt/live/:ro
    restart: always
    stop_grace_period: 1m
    # Uncomment if using `ENABLE_FAIL2BAN=1`:
    # cap_add:
    #   - NET_ADMIN
    healthcheck:
      test: "ss --listening --tcp | grep -P 'LISTEN.+:smtp' || exit 1"
      timeout: 3s
      retries: 0

  # If you don't yet have your own `nginx-proxy` and `acme-companion` setup,
  # here is an example you can use:
  reverse-proxy:
    image: nginxproxy/nginx-proxy
    container_name: nginx-proxy
    restart: always
    ports:
      # Port  80: Required for HTTP-01 challenges to `acme-companion`.
      # Port 443: Only required for containers that need access over HTTPS. TLS-ALPN-01 challenge not supported.
      - "80:80"
      - "443:443"
    volumes:
      # `certs/`:      Managed by the `acme-companion` container (_read-only_).
      # `docker.sock`: Required to interact with containers via the Docker API.
      - ./docker-data/nginx-proxy/html/:/usr/share/nginx/html/
      - ./docker-data/nginx-proxy/vhost.d/:/etc/nginx/vhost.d/
      - ./docker-data/acme-companion/certs/:/etc/nginx/certs/:ro
      - /var/run/docker.sock:/tmp/docker.sock:ro

  acme-companion:
    image: nginxproxy/acme-companion
    container_name: nginx-proxy-acme
    restart: always
    environment:
      # When `volumes_from: [nginx-proxy]` is not supported,
      # reference the _reverse-proxy_ `container_name` here:
      # - DEFAULT_EMAIL=alice@gitcoins.io
      - NGINX_PROXY_CONTAINER=nginx-proxy
    volumes:
      # `html/`:       Write ACME HTTP-01 challenge files that `nginx-proxy` will serve.
      # `vhost.d/`:    To enable web access via `nginx-proxy` to HTTP-01 challenge files.
      # `certs/`:      To store certificates and private keys.
      # `acme-state/`: To persist config and state for the ACME provisioner (`acme.sh`).
      # `docker.sock`: Required to interact with containers via the Docker API.
      - ./docker-data/nginx-proxy/html/:/usr/share/nginx/html/
      - ./docker-data/nginx-proxy/vhost.d/:/etc/nginx/vhost.d/
      - ./docker-data/acme-companion/certs/:/etc/nginx/certs/:rw
      - ./docker-data/acme-companion/acme-state/:/etc/acme.sh/
      - /var/run/docker.sock:/var/run/docker.sock:ro
```

Note: please mount the certs generated by lesencrypt in the acme-companion container to the mailserver container. Add following voluems info to the mailserver in the compose file.

```yaml
      - ./docker-data/acme-companion/certs/:/etc/letsencrypt/live/:ro
```

#### 2. Configure Docker-Mailserver for mailgun and TLS 
Modify or create the environment file (`03-tls-mailserver.env`) for `docker-mailserver` to include **ssl settings**.

##### Add the following lines:
```ini
# empty => SSL disabled
# letsencrypt => Enables Let's Encrypt certificates
# custom => Enables custom certificates
# manual => Let's you manually specify locations of your SSL certificates for non-standard cases
# self-signed => Enables self-signed certificates
SSL_TYPE=letsencrypt
VIRTUAL_HOST=mail.gitcoins.io
LETSENCRYPT_HOST=mail.gitcoins.io
```

---

#### 3. Restart Docker-Mailserver
Restart the `docker-mailserver` container to apply changes:

```sh
docker compose  -f 03-tls-compose.yaml down
docker compose  -f 03-tls-compose.yaml up
docker ps
```

Add Users:

```bash
docker exec -it mailserver setup email add alice@gitcoins.io
docker exec -it mailserver setup email add bob@gitcoins.io
```

---

#### 4. Verify Mail Sending with stl
To test **explicit TLS (STARTTLS)** and **implicit TLS (SMTPS)** with `swaks`, you can slightly modify your base command. Here's how to do both:

---

##### 4.1 **Explicit TLS (STARTTLS) — Port 587**

```yaml
ports:
  - "25:25"    # SMTP  (explicit TLS => STARTTLS, Authentication is DISABLED => use port 465/587 instead)
  - "143:143"  # IMAP4 (explicit TLS => STARTTLS)
  - "465:465"  # ESMTP (implicit TLS)
  - "587:587"  # ESMTP (explicit TLS => STARTTLS)
  - "993:993"  # IMAP4 (implicit TLS)
```

This starts as plaintext, then upgrades to TLS using `STARTTLS`.

```bash
swaks \
  --to wofwoofwooofwoooof@gmail.com \
  --from alice@gitcoins.io \
  --server mail.gitcoins.io \
  --port 587 \
  --auth LOGIN \
  --auth-user alice@gitcoins.io \
  --auth-password alice \
  --tls \
  --h-Subject: "Hello with STARTTLS" \
  --body 'Testing explicit TLS (STARTTLS) via swaks!'
```

- `--tls` tells swaks to use STARTTLS (explicit TLS).
- Port `587` is the standard port for submission with STARTTLS.

---

##### 4.2 **Implicit TLS (SMTPS) — Port 465**

This uses TLS from the beginning of the connection.

```bash
swaks \
  --to wofwoofwooofwoooof@gmail.com \
  --from alice@gitcoins.io \
  --server mail.gitcoins.io \
  --port 465 \
  --auth LOGIN \
  --auth-user alice@gitcoins.io \
  --auth-password alice \
  --tls-on-connect \
  --h-Subject: "Hello with Implicit TLS" \
  --body 'Testing implicit TLS (SMTPS) via swaks!'
```

Please see the diff of --tls and --tls-on-connect at the end of this page.

---

#### 5. Verify Mail receiving with stl

To **receive mail securely with explicit and implicit TLS**, you'll typically be using **IMAP or POP3**. `swaks` is designed for sending mail (SMTP), so it doesn’t handle receiving. For receiving, you’ll use tools like:

- `openssl s_client` (for testing TLS handshake)
- `curl` (for simple IMAP/POP3 retrieval)
- `mbsync` or `fetchmail` (for syncing mailboxes)
- `imap-cli`, `offlineimap`, or dedicated email clients

But let’s stick to **basic testing with TLS** using tools available on most systems. Below are examples for both **explicit** and **implicit** TLS using `openssl s_client`.

---

##### 5.1 **Receiving Mail with IMAP over Explicit TLS (STARTTLS) — Port 143**

```bash
openssl s_client -connect mail.gitcoins.io:143 -starttls imap
```

This will:

- Connect over plaintext
- Issue `STARTTLS` to upgrade to TLS

You should see the certificate details and then can manually issue IMAP commands like:

```
a1 LOGIN alice@gitcoins.io alice
a2 SELECT INBOX
a3 FETCH 1 BODY[HEADER]
a4 LOGOUT
```

---

##### 5.2 **Receiving Mail with IMAP over Implicit TLS — Port 993**

```bash
openssl s_client -connect mail.gitcoins.io:993
```

This will:

- Connect using TLS immediately (implicit)
- Then allow IMAP commands

You should see the certificate details and then can manually issue IMAP commands like:

```
a1 LOGIN alice@gitcoins.io alice
a2 SELECT INBOX
a3 FETCH 1 BODY[HEADER]
a4 LOGOUT
```

---


##### Optional: Verifying TLS Certificate

To print cert info, add:

```bash
openssl s_client -connect mail.gitcoins.io:993 -showcerts
```

---

### Summary

If your goal is:
- **Secure mail protocols** like SMTP/IMAP over TLS: ✔ already supported by docker-mailserver (ports 465, 587, 993)
- **Secure web access** to a roundcute interface: Use `nginx-proxy` + `acme-companion` is ready for use


### **Difference Between `--tls-on-connect` and `--tls` in `swaks`**
The flags control how TLS encryption is negotiated with the SMTP server. Here’s the breakdown:

| **Flag**               | **Behavior**                                                                 | **Used For**               |
|------------------------|-----------------------------------------------------------------------------|----------------------------|
| `--tls-on-connect`     | Starts TLS **immediately** upon connection (before SMTP handshake).          | Port **465 (SMTPS)**       |
| `--tls`                | Uses **STARTTLS** (upgrades an existing plaintext connection to TLS).       | Port **587 (Submission)**  |

---

### **When to Use Which?**
#### **1. `--tls-on-connect` (Port 465)**
- **How it works**:  
  - TLS encryption begins **before** any SMTP commands (like `EHLO`) are sent.  
  - The entire session is encrypted from the start (aka **"implicit TLS"**).  
- **Example**:  
  ```bash
  swaks \
    --server mail.gitcoins.io:465 \
    --tls-on-connect \  # <-- Critical for port 465
    --auth LOGIN \
    --auth-user alice@gitcoins.io
  ```

#### **2. `--tls` (Port 587)**
- **How it works**:  
  - Connects in plaintext, then upgrades to TLS **after** `EHLO` using `STARTTLS`.  
  - The server must advertise `STARTTLS` in its `EHLO` response.  
- **Example**:  
  ```bash
  swaks \
    --server mail.gitcoins.io:587 \
    --tls \  # <-- Uses STARTTLS
    --auth LOGIN \
    --auth-user alice@gitcoins.io
  ```

---

### **Why `--tls-on-connect` Worked for You**
- Your server expects **implicit TLS** on port 465 (standard for SMTPS).  
- `--tls` (STARTTLS) fails because:  
  - The server isn’t listening for plaintext commands first.  
  - You’d see errors like:  
    ```plaintext
    SSL_accept error: wrong version number
    ```

---

### **Key Takeaways**
1. **Port 465** → Always use `--tls-on-connect`.  
2. **Port 587** → Use `--tls` (STARTTLS).  
3. Mixing them up causes handshake failures.  

---

### **Debugging Tips**
- Check server capabilities:  
  ```bash
  openssl s_client -connect mail.gitcoins.io:465 -quiet
  EHLO example.com  # Should show "250-STARTTLS" if STARTTLS is supported
  ```
- Test both ports:  
  ```bash
  swaks --server mail.gitcoins.io:587 --tls --auth LOGIN...
  swaks --server mail.gitcoins.io:465 --tls-on-connect --auth LOGIN...
  ```

Let me know if you need further clarification! 🚀