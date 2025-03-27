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

### 🧠 Example Config (passwd-file + static userdb):

```conf
# passdb: authenticates user
passdb {
  driver = passwd-file
  args = /etc/dovecot/users
}

# userdb: sets mail location
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}
```

- `/etc/dovecot/users` would contain lines like:
  ```
  user1@example.com:{SHA512-CRYPT}$6$abcdef...
  ```

---

