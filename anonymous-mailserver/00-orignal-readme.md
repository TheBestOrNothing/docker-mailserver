To test sending an email from `alice` to `bob` using the configured Docker Mailserver, follow these steps:

---

### **1. Ensure the Mailserver is Running**
Make sure the mail server container is up and running:
```bash
docker compose  -f 00-orignal-compose.yaml up
docker ps
```
You should see the `mailserver` container listed.

---

### **2. Create User Accounts for Alice and Bob**
You need to create user accounts for `alice` and `bob` in the mail server. Use the `setup.sh` script provided by the Docker Mailserver.

#### Add Users:
```bash
docker exec -it mailserver setup email add alice@example.com
docker exec -it mailserver setup email add bob@example.com
```
- Replace `example.com` with your actual domain.
- You will be prompted to set passwords for both users.

---

### **3. Test Sending an Email**
You can use a command-line email client like `swaks` to send an email from `alice` to `bob`.

#### Install `swaks` (if not already installed):
```bash
sudo apt-get install swaks  # For Debian/Ubuntu
sudo yum install swaks      # For CentOS/RHEL
brew install swaks          # For macOS
```

#### Send an Email:
```bash
swaks --to bob@example.com --from alice@example.com --server localhost --port 587 --no-tls --auth-user alice@example.com --auth-password <alice_password>
```
- Replace `<alice_password>` with the password you set for `alice`.
- The `--port 587` flag uses the SMTP submission port with STARTTLS encryption.

---

### **4. Check the Email in Bob's Mailbox**
You can use an IMAP client or the `setup.sh` script to check if the email was delivered to `bob`.

#### Check Mailbox Using `setup.sh`:
```bash
docker exec -it mailserver setup email list bob@example.com
```
This will list the emails in `bob`'s mailbox.

---

### **5. Verify Logs (Optional)**
If the email doesn't arrive, check the mail server logs for errors:
```bash
docker logs mailserver
```
Look for any issues related to authentication, delivery, or TLS.

---

### **Troubleshooting**
- Ensure the domain (`example.com`) resolves correctly to the mail server.
- Verify that the ports (`25`, `465`, `587`, `993`) are open and not blocked by a firewall.
- Check the `mailserver.env` file for correct configuration (e.g., `ENABLE_SPAMASSASSIN`, `ENABLE_CLAMAV`, etc.).