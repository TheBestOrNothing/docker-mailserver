here’s how you can set up **OAuth2 / OpenID Connect login for Roundcube with Microsoft (like Azure AD)** using the `roundcube-oauth2` plugin in your Docker Compose setup.

## "How the feature works"

1. A **mail client must have support** to acquire an OAuth2 token from your IdP (_however many clients lack generic OAuth2 / OIDC provider support_).
2. The mail client then provides that token as the user password via the login mechanism `XOAUTH2` or `OAUTHBEARER`.
3. DMS (Dovecot) will then check the validity of that token against the Authentication Service it was configured with.
4. If the response returned is valid for the user account, authentication is successful.

[**XOAUTH2**][google::xoauth2-docs] (_Googles widely adopted implementation_) and **OAUTHBEARER** (_the newer variant standardized by [RFC 7628][rfc::7628] in 2015_) are supported as standards for verifying that a OAuth Bearer Token (_[RFC 6750][rfc::6750] from 2012_) is valid at the identity provider that created the token. The token itself in both cases is expected to be can an opaque _Access Token_, but it is possible to use a JWT _ID Token_ (_which encodes additional information into the token itself_).

A mail client like Thunderbird has limited OAuth2 / OIDC support. The software maintains a hard-coded list of providers supported. Roundcube is a webmail client that does have support for generic providers, allowing you to integrate with a broader range of IdP services.

---

## Config Oauth2 

This assumes you have already set up:
- A working DMS server
- An OIDC server 
- A Roundcube server

### **Step 1: Configure Docker-Mailserver for Oauth2**
Modify or create the environment file (`05-oauth2-mailserver.env`) for `docker-mailserver` to include **Oauth2 settings**.

### Add the following lines:
```ini
# empty => OAUTH2 authentication is disabled
# 1 => OAUTH2 authentication is enabled
ENABLE_OAUTH2=1

# Specify the user info endpoint URL of the oauth2 provider
# Example: https://oauth2.example.com/userinfo/
OAUTH2_INTROSPECTION_URL=https://oidc.coinsgpt.io/me
```

### **Step 2: OIDC Provider **

1. Create a new OAuth2 provider like node-oidc-provider `https://github.com/panva/node-oidc-provider`.
2. Note the client id and client secret. Roundcube will need this.
3. Set the allowed redirect url to the equivalent of `https://roundcube.gitcoins.io/index.php/login/oauth` for your RoundCube instance.

Go to https://oidc.coinsgpt.io/.well-known/openid-configuration and add focus the following items.

```
"userinfo_endpoint": "https://oidc.coinsgpt.io/me",
"introspection_endpoint": "https://oidc.coinsgpt.io/token/introspection",
"token_endpoint": "https://oidc.coinsgpt.io/token",
"authorization_endpoint": "https://oidc.coinsgpt.io/auth",
"device_authorization_endpoint": "https://oidc.coinsgpt.io/device/auth",
```

### Step 3: Configure Plugin in Roundcube

Create or edit this file:

📄 `./docker-data/roundcube/config/config.inc.php`:

```php
<?php
  $config['imap_auth_type'] = 'PLAIN';
  $config['smtp_user'] = '%u';
  $config['smtp_pass'] = '%p';
  $config['oauth_provider'] = 'generic';
  $config['oauth_provider_name'] = 'MetaMask';
  $config['oauth_client_id'] = 'CLIENT_ID';
  $config['oauth_client_secret'] = 'SECRET';
  $config['oauth_auth_uri'] = 'https://oidc.coinsgpt.io/auth';
  $config['oauth_token_uri'] = 'https://oidc.coinsgpt.io/token';
  $config['oauth_identity_uri'] = 'https://oidc.coinsgpt.io/me';

  // Optional: disable SSL certificate check on HTTP requests to OAuth server. For possible values, see:
  // http://docs.guzzlephp.org/en/stable/request-options.html#verify
  $config['oauth_verify_peer'] = false;

  $config['oauth_scope'] = 'email openid profile';
  $config['oauth_identity_fields'] = ['email'];

  // Boolean: automatically redirect to OAuth login when opening Roundcube without a valid session
  $config['oauth_login_redirect'] = false;
```

Note: please mount the oauth2 configuration to the roundcube container. Add following voluems info to the mailserver in the compose file.

```yaml
      - ./docker-data/roundcube/config/:/var/roundcube/config/:rw
```


---

## ✅ Test It

### 🔧 Verify Oauth2 Config for Dovecot (simplified)

```bash
docker exec -it mailserver dovecot -n
```

Oauth2 auth mechanisms, passdb and userdb info

```conf

auth_mechanisms = plain login oauthbearer xoauth2

passdb {
  args = scheme=SHA512-CRYPT username_format=%u /etc/dovecot/userdb
  driver = passwd-file
  mechanisms = plain login
}

passdb {
  args = /etc/dovecot/dovecot-oauth2.conf.ext
  driver = oauth2
  mechanisms = xoauth2 oauthbearer
}

userdb {
  args = username_format=%u /etc/dovecot/userdb
  default_fields = uid=docker gid=docker home=/var/mail/%d/%u/home/
  driver = passwd-file
}

```

In `/etc/dovecot/oauth2.conf.ext`, you'd find how Dovecot verifies tokens, e.g., via introspection URL or JWT public keys.

---

### Option 1: Test with MetaMask Mobile App 

You should see an **OAuth2 login button for MetaMask**. It will redirect you to the OIDC login page and return to Roundcube after authentication.

Add your Metamask accout as new users:

```bash
docker exec -it mailserver setup email add 0x4477610799e7910f0e40f64da702aa9ffcf929ac@gitcoins.io
```

To click `MetaMask` to login with web ui `https://roundcube.gitcoins.io`

Scan the QR code by MetaMask mobile or use Metamask plugin to connect and sign

The MetaMask OIDC server will verify the signment and then return the access token for login

### Option 2: Test with OIDC token (unable to verify)

1. Retrieve the access_token by code

```bash
curl -X POST https://oidc.coinsgpt.io/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=authorization_code" \
  -d "code=ebzKnEhKQzv3NSwcuJr9pg8mAZ_6sQ5Fw2pr7_G_yKs" \
  -d "redirect_uri=https://roundcube.gitcoins.io/index.php/login/oauth" \
  -d "client_id=CLIENT" \
  -d "client_secret=SECRET"
```

2. Retrieve the access_token by code

```bash
  # Shell into your DMS container:
  docker exec -it mailserver /bin/bash

  # Adjust these variables for the methods below to use:
  export AUTH_METHOD='OAUTHBEARER' USER_ACCOUNT='0x4477610799e7910f0e40f64da702aa9ffcf929ac@gitcoins.io' ACCESS_TOKEN='aZQ9FamBfuIvtv5IIME6JtWUxeJcfgvd'

  # Authenticate via IMAP (Dovecot):
  curl --silent --url 'imap://localhost:143' \
      --login-options "AUTH=${AUTH_METHOD}" --user "${USER_ACCOUNT}" --oauth2-bearer "${ACCESS_TOKEN}" \
      --request 'LOGOUT' \
      && grep "dovecot: imap-login: Login: user=<${USER_ACCOUNT}>, method=${AUTH_METHOD}" /var/log/mail/mail.log

  # Authenticate via SMTP (Postfix), sending a mail with the same sender(from) and recipient(to) address:
  # NOTE: `curl` seems to require `--upload-file` with some mail content provided to test SMTP auth.
  curl --silent --url 'smtp://localhost:587' \
      --login-options "AUTH=${AUTH_METHOD}" --user "${USER_ACCOUNT}" --oauth2-bearer "${ACCESS_TOKEN}" \
      --mail-from "${USER_ACCOUNT}" --mail-rcpt "${USER_ACCOUNT}" --upload-file - <<< 'RFC 5322 content - not important' \
      && grep "postfix/submission/smtpd.*, sasl_method=${AUTH_METHOD}, sasl_username=${USER_ACCOUNT}" /var/log/mail/mail.log
  ```