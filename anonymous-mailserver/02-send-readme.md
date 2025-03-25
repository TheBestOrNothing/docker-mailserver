To configure **docker-mailserver** to send mail using **Mailgun** as a third-party SMTP relay.

Below is a step-by-step guide to adding a new domain in **Mailgun** and setting up **DKIM, DMARC, and SPF** records in your DNS.

---

## **Step 1: Add a New Domain to Mailgun**
1. **Login to Mailgun**:  
   Go to [Mailgun Dashboard](https://app.mailgun.com/).
   
2. **Go to "Sending" → "Domains"**:  
   Click on **Add New Domain**.

3. **Enter Your Domain**:  
   - Use a subdomain like `mail.yourdomain.com` (recommended).  
   - If you want to use the root domain (`yourdomain.com`), it's possible but **not recommended** because it may affect your other email services.  
   - Choose **EU or US region** based on your preference.

4. **Select DKIM Key Length**:  
   - Default is **2048-bit** (recommended for security).  
   - If your DNS provider doesn't support 2048-bit, select **1024-bit**.

5. **Click "Add Domain"**:  
   - Mailgun will now generate **DNS records** that you need to add to your domain’s DNS.

---

## **Step 2: Configure DNS (SPF, DKIM, DMARC)**
After adding your domain, Mailgun will provide DNS records that need to be added to your domain’s **DNS provider** (e.g., Cloudflare, GoDaddy, Namecheap, AWS Route 53, etc.).

**SPF Record (Sender Policy Framework)**: ensures only authorized servers (Mailgun) can send emails on your domain’s behalf.

**DKIM Record (DomainKeys Identified Mail)**: helps prevent email spoofing by signing emails digitally.

**DMARC Record (Domain-based Message Authentication, Reporting & Conformance)**: helps protect against phishing and abuse.

---

## **Step 3: Verify DNS Records in Mailgun**
1. **Go to Mailgun Dashboard → Domains → Click Your Domain**.
2. Waitting  for DNS changes to propagate.
3. Click **Verify DNS Settings**.
4. If everything is correct, you will see **green checkmarks ✅**.

```bash
swaks --auth \
	--server smtp.mailgun.org \
	--port 587 \
	--au postmaster@mail.gitcoins.io\
	--ap "password for postmaster user" \
	--to user@gmail.com \
	--h-Subject: "Hello" \
	--body 'Testing some Mailgun awesomness!'
```

If everything is configured correctly, you should receive an email via Mailgun.

---

## **Step 5: Set Up Mailgun Credentials**
Before configuring `docker-mailserver`, ensure you have a **Mailgun SMTP username and password** from your Mailgun account.

- **SMTP Server**: `smtp.mailgun.org`
- **Port**: `587` (TLS) or `465` (SSL)
- **Username**: `postmaster@mail.gitcoins.io`
- **Password**: (Found in Mailgun dashboard)

---

## **Step 6: Configure Docker-Mailserver for Mailgun**
Modify or create the environment file (`02-send-mailserver.env`) for `docker-mailserver` to include **relay settings**.

### Add the following lines:
```ini
# Enable SMTP Relay
RELAY_HOST=smtp.mailgun.org
RELAY_PORT=587
RELAY_USER=postmaster@mail.gitcoins.io
RELAY_PASSWORD=your-mailgun-password
```

---

## **Step 7: Restart Docker-Mailserver**
Restart the `docker-mailserver` container to apply changes:

```sh
docker compose  -f 02-send-compose.yaml down
docker compose  -f 02-send-compose.yaml up
docker ps
```

Add Users:

```bash
docker exec -it mailserver setup email add alice@gitcoins.io
docker exec -it mailserver setup email add bob@gitcoins.io
```

---

## **Step 8: Verify Mail Sending**
To test email sending via Mailgun, you can use **swaks** inside the running `mailserver` container:

```bash
swaks \
  --to user@gmail.com \
  --from alice@gitcoins.io \
  --server mail.gitcoins.io \
  --port 587 \
  --auth LOGIN \
  --auth-user alice@gitcoins.io \
  --auth-password "your_password_here" \
  --no-tls \
  --h-Subject: "Hello" \
  --body 'Testing some Mailgun awesomness!'
```
If everything is configured correctly, you should receive an email via alice@gitcoins.

---

### **Additional Notes**
- Make sure your Mailgun domain is **verified** and has **proper DNS records** (SPF, DKIM, MX).
- Ensure your ISP allows outbound connections on **port 587**.
- Check the logs if emails are not sent:

  ```sh
  docker logs mailserver
  ```
---

#### **1. Verify Dovecot Authentication**
Open the Dovecot authentication configuration file:

```bash
docker exec -it mailserver cat /etc/dovecot/conf.d/10-master.conf
```
Find this section service auth to allow Postfix to use Dovecot authentication:

```plaintext
service auth {

  # Postfix smtp-auth
  unix_listener /dev/shm/sasl-auth.sock {
    mode = 0660
    user = postfix
    group = postfix
  }

}
```

To make sure the sock is exit in the contianer.

```bash
docker exec -it mailserver ls -l /dev/shm/sasl-auth.sock
```
srw-rw---- 1 postfix postfix 0 Mar 24 11:38 /dev/shm/sasl-auth.sock

---

#### **2. Verify configure Postfix to Use Dovecot SASL**
Edit the Postfix main configuration file:

```bash
docker exec -it mailserver cat /etc/postfix/main.cf
```

To make sure the following lines in Postfix main.cf used by Dovecot for authentication:

```plaintext
smtpd_sasl_type = dovecot
smtpd_sasl_path = private/auth
smtpd_sasl_auth_enable = yes
smtpd_sasl_security_options = noanonymous
smtpd_sasl_local_domain = $myhostname
smtpd_recipient_restrictions =
    permit_sasl_authenticated,
    permit_mynetworks,
    reject_unauth_destination
```

---
