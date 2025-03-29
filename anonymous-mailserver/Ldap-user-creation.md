## ✅ Step-by-Step: Create a User in LDAP via Command Line

### 🔹 1. Create an LDIF File

Create a file called `add-alice.ldif`:

```ldif
dn: uid=alice,ou=users,dc=gitcoins,dc=io
objectClass: inetOrgPerson
objectClass: PostfixBookMailAccount
cn: Alice
givenName: Alice
sn: User
uid: alice
userPassword:: e1NTSEF9ZUx0cUdwaWQraGtTVmh4dnNkVFB6dHY0dWFwUm9mR3g=
mail: alice@gitcoins.io
mailAlias: postmaster@gitcoins.io
mailGroupMember: employees@gitcoins.io
mailHomeDirectory: /var/mail/gitcoins.io/alice/
mailStorageDirectory: maildir:/var/mail/gitcoins.io/alice/
mailEnabled: TRUE
mailUidNumber: 5000
mailGidNumber: 5000
mailQuota: 10240
```

Note:
- `userPassword::` is base64 encoded. This value is already in your example.
- You can generate a secure password hash using `slappasswd` if needed.

---

### 🔹 2. Add the User via `ldapadd`

Run this command:

```bash
ldapadd -x \
  -H ldap://ldap.gitcoins.io \
  -D "cn=admin,dc=gitcoins,dc=io" \
  -w adminpassword \
  -f add-alice.ldif
```

Expected output:
```
adding new entry "uid=alice,ou=users,dc=gitcoins,dc=io"
```

---

### 🔹 3. Verify the User Was Added

Search with:
```bash
ldapsearch -x \
  -H ldap://ldap.gitcoins.io \
  -D "cn=admin,dc=gitcoins,dc=io" \
  -w adminpassword \
  -b "ou=users,dc=gitcoins,dc=io" \
  "(uid=alice)"
```

---

You **can create a user directly via the command line** using `ldapadd` and a **here-document** in bash — no need to create a separate `.ldif` file on disk.


## ✅ Create LDAP User Without an `.ldif` File

### 📌 Using `ldapadd` with a **here-document**:
```bash
ldapadd -x \
  -H ldap://ldap.gitcoins.io \
  -D "cn=admin,dc=gitcoins,dc=io" \
  -w adminpassword <<EOF
dn: uid=alice,ou=users,dc=gitcoins,dc=io
objectClass: inetOrgPerson
objectClass: PostfixBookMailAccount
cn: Alice
givenName: Alice
sn: User
uid: alice
userPassword:: e1NTSEF9ZUx0cUdwaWQraGtTVmh4dnNkVFB6dHY0dWFwUm9mR3g=
mail: alice@gitcoins.io
mailAlias: postmaster@gitcoins.io
mailGroupMember: employees@gitcoins.io
mailHomeDirectory: /var/mail/gitcoins.io/alice/
mailStorageDirectory: maildir:/var/mail/gitcoins.io/alice/
mailEnabled: TRUE
mailUidNumber: 5000
mailGidNumber: 5000
mailQuota: 10240
EOF
```

---

you can also **create an LDAP user programmatically** using libraries in various languages such as **Python**, **Node.js**, **Go**, etc. Below are code examples in popular languages to create a user entry in LDAP (equivalent to your `alice@gitcoins.io` case).

## ✅ Option 1: **Python (using `ldap3`)**

```python
from ldap3 import Server, Connection, ALL, MODIFY_ADD

server = Server('ldap://ldap.gitcoins.io', get_info=ALL)
conn = Connection(server, user='cn=admin,dc=gitcoins,dc=io', password='adminpassword', auto_bind=True)

dn = 'uid=alice,ou=users,dc=gitcoins,dc=io'
attributes = {
    'objectClass': ['inetOrgPerson', 'PostfixBookMailAccount'],
    'cn': 'Alice',
    'givenName': 'Alice',
    'sn': 'User',
    'uid': 'alice',
    'mail': 'alice@gitcoins.io',
    'mailAlias': 'postmaster@gitcoins.io',
    'mailGroupMember': 'employees@gitcoins.io',
    'mailHomeDirectory': '/var/mail/gitcoins.io/alice/',
    'mailStorageDirectory': 'maildir:/var/mail/gitcoins.io/alice/',
    'mailEnabled': 'TRUE',
    'mailUidNumber': '5000',
    'mailGidNumber': '5000',
    'mailQuota': '10240',
    'userPassword': '{SSHA}e1NTSEF9ZUx0cUdwaWQraGtTVmh4dnNkVFB6dHY0dWFwUm9mR3g='
}

conn.add(dn, attributes=attributes)

print("User created:", conn.result)
conn.unbind()
```

> ✅ Install with: `pip install ldap3`

---

## ✅ Option 2: **Node.js (using `ldapjs`)**

```javascript
const ldap = require('ldapjs');

const client = ldap.createClient({
  url: 'ldap://ldap.gitcoins.io'
});

client.bind('cn=admin,dc=gitcoins,dc=io', 'adminpassword', function(err) {
  if (err) throw err;

  const entry = {
    objectClass: ['inetOrgPerson', 'PostfixBookMailAccount'],
    cn: 'Alice',
    givenName: 'Alice',
    sn: 'User',
    uid: 'alice',
    mail: 'alice@gitcoins.io',
    mailAlias: 'postmaster@gitcoins.io',
    mailGroupMember: 'employees@gitcoins.io',
    mailHomeDirectory: '/var/mail/gitcoins.io/alice/',
    mailStorageDirectory: 'maildir:/var/mail/gitcoins.io/alice/',
    mailEnabled: 'TRUE',
    mailUidNumber: '5000',
    mailGidNumber: '5000',
    mailQuota: '10240',
    userPassword: '{SSHA}e1NTSEF9ZUx0cUdwaWQraGtTVmh4dnNkVFB6dHY0dWFwUm9mR3g='
  };

  client.add('uid=alice,ou=users,dc=gitcoins,dc=io', entry, function(err) {
    if (err) console.error('Add failed:', err);
    else console.log('User added.');
    client.unbind();
  });
});
```

> ✅ Install with: `npm install ldapjs`

---

## ✅ Option 3: **Go (using `gopkg.in/ldap.v3`)**

```go
package main

import (
    "fmt"
    "log"
    "gopkg.in/ldap.v3"
)

func main() {
    l, err := ldap.DialURL("ldap://ldap.gitcoins.io")
    if err != nil {
        log.Fatal(err)
    }
    defer l.Close()

    err = l.Bind("cn=admin,dc=gitcoins,dc=io", "adminpassword")
    if err != nil {
        log.Fatal(err)
    }

    addReq := ldap.NewAddRequest("uid=alice,ou=users,dc=gitcoins,dc=io", nil)
    addReq.Attribute("objectClass", []string{"inetOrgPerson", "PostfixBookMailAccount"})
    addReq.Attribute("cn", []string{"Alice"})
    addReq.Attribute("givenName", []string{"Alice"})
    addReq.Attribute("sn", []string{"User"})
    addReq.Attribute("uid", []string{"alice"})
    addReq.Attribute("mail", []string{"alice@gitcoins.io"})
    addReq.Attribute("mailAlias", []string{"postmaster@gitcoins.io"})
    addReq.Attribute("mailGroupMember", []string{"employees@gitcoins.io"})
    addReq.Attribute("mailHomeDirectory", []string{"/var/mail/gitcoins.io/alice/"})
    addReq.Attribute("mailStorageDirectory", []string{"maildir:/var/mail/gitcoins.io/alice/"})
    addReq.Attribute("mailEnabled", []string{"TRUE"})
    addReq.Attribute("mailUidNumber", []string{"5000"})
    addReq.Attribute("mailGidNumber", []string{"5000"})
    addReq.Attribute("mailQuota", []string{"10240"})
    addReq.Attribute("userPassword", []string{"{SSHA}e1NTSEF9ZUx0cUdwaWQraGtTVmh4dnNkVFB6dHY0dWFwUm9mR3g="})

    err = l.Add(addReq)
    if err != nil {
        log.Fatal(err)
    }

    fmt.Println("User added successfully.")
}
```

> ✅ Install with:  
```bash
go get gopkg.in/ldap.v3
```

---
