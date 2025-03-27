In Dovecot, **user databases** and **password databases** serve different but complementary purposes in the authentication process:

---

### 🔐 **Password Database (passdb)**

- **Purpose**: Verifies the user's **credentials** (typically username + password).
- **Checks**: Whether the supplied password is correct.
- **Can contain**: Password hashes, authentication mechanisms, user-specific settings (optionally).
- **Examples**:
  - `passwd` (Linux system users)
  - `passwd-file` (custom flat file)
  - `ldap` or `sql` (LDAP/SQL-based credentials)
  - `XOAUTH2` or `OAUTH2` (OAUTH2-based credentials)

---

### 👤 **User Database (userdb)**

- **Purpose**: Provides **user-specific information** needed after successful authentication.
- **Returns**:
  - Home directory path
  - UID/GID
  - Mailbox location
  - Optional: user-specific quotas, environment variables, etc.
- **Examples**:
  - `passwd` (system users)
  - `static` (hardcoded values)
  - `sql` or `ldap` (pull data from a database)

---

### 🔄 **Relationship Between `passdb` and `userdb`**

1. **Authentication starts with `passdb`**:
   - Checks the username and password.
   - If matched, optionally returns `user = something` to override the username.

2. **Then Dovecot looks up `userdb`**:
   - Using the (possibly overridden) username.
   - Retrieves mail-specific info (like `home`, `mail`, UID/GID).

---

### 🔧 Verify Dovecot Config for Dovecot (simplified)

```bash
docker exec -it mailserver dovecot -n
```

1. Plain auth mechanisms

```conf
auth_mechanisms = plain login

userdb {
  args = username_format=%u /etc/dovecot/userdb
  default_fields = uid=docker gid=docker home=/var/mail/%d/%u/home/
  driver = passwd-file
}

passdb {
  args = scheme=SHA512-CRYPT username_format=%u /etc/dovecot/userdb
  driver = passwd-file
  mechanisms = plain login
}

```

2. Oauth2 auth mechanisms

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

---
