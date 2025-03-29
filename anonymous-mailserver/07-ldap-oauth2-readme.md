To add **LDAP authentication** using the `bitnami/ldap` container to your `docker-mailserver` setup, and adapt your `07-ldap-oauth2-mailserver.env` accordingly, follow these steps:

Reference: https://docker-mailserver.github.io/docker-mailserver/latest/config/account-management/provisioner/ldap/

---

## ✅ Step 1: Add `bitnami/ldap` to `docker-compose.yml`

Add this block **before** your `mailserver` service:

```yaml
  openldap:
    image: bitnami/openldap:latest
    container_name: openldap
    hostname: ldap.gitcoins.io
    environment:
      - LETSENCRYPT_HOST=ldap.gitcoins.io
      - VIRTUAL_HOST=ldap.gitcoins.io
      - LDAP_ROOT=dc=gitcoins,dc=io
      - LDAP_ADMIN_USERNAME=admin
      - LDAP_ADMIN_PASSWORD=adminpassword
      - LDAP_USERS=customuser
      - LDAP_PASSWORDS=custompassword
      - LDAP_ADMIN_DN=cn=admin,dc=gitcoins,dc=io
      - LDAP_SKIP_DEFAULT_TREE=yes 
    ports:
      - "389:1389"
      - "636:1636"
    volumes:
      - ./docker-data/openldap/ldifs/:/ldifs/:ro
      - ./docker-data/openldap/schemas/:/schemas/:ro
```

You can change the users/passwords and the root domain to match your setup.

---

## ✅ Step 2: Modify `mailserver` `depends_on` and `env_file`

Make sure `mailserver` depends on `ldap`:

```yaml
    depends_on:
      - nginx-proxy-acme
      - ldap
```

---

## ✅ Step 3: Create/Update `07-ldap-oauth2-mailserver.env`

Here’s a basic template for LDAP-related variables. The following is different between 05-oauth2-mailserver.env and 07-ldap-oauth2-mailserver.

```ini
< ACCOUNT_PROVISIONER=LDAP
> ACCOUNT_PROVISIONER=

< LDAP_START_TLS=no
> LDAP_START_TLS=

< LDAP_SERVER_HOST=ldap://ldap.gitcoins.io:1389
> LDAP_SERVER_HOST=

< LDAP_SEARCH_BASE=ou=users,dc=gitcoins,dc=io
> LDAP_SEARCH_BASE=

< LDAP_BIND_DN=cn=admin,dc=gitcoins,dc=io
> LDAP_BIND_DN=

< LDAP_BIND_PW=adminpassword
> LDAP_BIND_PW=

< LDAP_QUERY_FILTER_USER=(&(mail=%s) (&(objectClass=PostfixBookMailAccount)(mailEnabled=TRUE)) )
> LDAP_QUERY_FILTER_USER=

< LDAP_QUERY_FILTER_GROUP=(&(mailGroupMember=%s) (&(objectClass=PostfixBookMailAccount)(mailEnabled=TRUE)) )
> LDAP_QUERY_FILTER_GROUP=

< LDAP_QUERY_FILTER_ALIAS=(&(mailAlias=%s) (| (objectClass=PostfixBookMailForward) (&(objectClass=PostfixBookMailAccount)(mailEnabled=TRUE)) ))
> LDAP_QUERY_FILTER_ALIAS=

< LDAP_QUERY_FILTER_DOMAIN=(| (& (|(mail=*@%s) (mailAlias=*@%s) (mailGroupMember=*@%s)) (&(objectClass=PostfixBookMailAccount)(mailEnabled=TRUE)) ) (&(mailAlias=*@%s)(objectClass=PostfixBookMailForward)) )
> LDAP_QUERY_FILTER_DOMAIN=

< DOVECOT_TLS=no
> DOVECOT_TLS=

< DOVECOT_USER_FILTER=(&(userID=%n)(objectClass=PostfixBookMailAccount))
> DOVECOT_USER_FILTER=

< DOVECOT_PASS_FILTER=(&(userID=%n)(objectClass=PostfixBookMailAccount))
> DOVECOT_PASS_FILTER=

< DOVECOT_AUTH_BIND=yes
> DOVECOT_AUTH_BIND=

< ENABLE_SASLAUTHD=1
> ENABLE_SASLAUTHD=0

< SASLAUTHD_MECHANISMS=ldap
> SASLAUTHD_MECHANISMS=

< SASLAUTHD_LDAP_FILTER=(&(userID=%U)(mailEnabled=TRUE))
> SASLAUTHD_LDAP_FILTER=

< SASLAUTHD_LDAP_START_TLS=no
> SASLAUTHD_LDAP_START_TLS=
```

---

## ✅ Step 4: Create LDAP schema

Add postfix-book.ldif in the docker-data/openldap/schemas.

```
dn: cn=postfix-book,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: postfix-book
olcAttributeTypes: {0}( 1.3.6.1.4.1.29426.1.10.1 NAME 'mailHomeDirectory' DESC 'The absolute path to the mail user home directory' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 SINGLE-VALUE )
olcAttributeTypes: {1}( 1.3.6.1.4.1.29426.1.10.2 NAME 'mailAlias' DESC 'RFC822 Mailbox - mail alias' EQUALITY caseIgnoreIA5Match SUBSTR caseIgnoreIA5SubstringsMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.26{256} )
olcAttributeTypes: {2}( 1.3.6.1.4.1.29426.1.10.3 NAME 'mailUidNumber' DESC 'UID required to access the mailbox' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
olcAttributeTypes: {3}( 1.3.6.1.4.1.29426.1.10.4 NAME 'mailGidNumber' DESC 'GID required to access the mailbox' EQUALITY integerMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.27 SINGLE-VALUE )
olcAttributeTypes: {4}( 1.3.6.1.4.1.29426.1.10.5 NAME 'mailEnabled' DESC 'TRUE to enable, FALSE to disable account' EQUALITY booleanMatch SYNTAX 1.3.6.1.4.1.1466.115.121.1.7 SINGLE-VALUE )
olcAttributeTypes: {5}( 1.3.6.1.4.1.29426.1.10.6 NAME 'mailGroupMember' DESC 'Name of a mail distribution list' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: {6}( 1.3.6.1.4.1.29426.1.10.7 NAME 'mailQuota' DESC 'Mail quota limit in kilobytes' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 )
olcAttributeTypes: {7}( 1.3.6.1.4.1.29426.1.10.8 NAME 'mailStorageDirectory' DESC 'The absolute path to the mail users mailbox' EQUALITY caseExactIA5Match SYNTAX 1.3.6.1.4.1.1466.115.121.1.26 SINGLE-VALUE )
# PostfixBook object classes:
olcObjectClasses: {0}( 1.3.6.1.4.1.29426.1.2.2.1 NAME 'PostfixBookMailAccount' DESC 'Mail account used in Postfix Book' SUP top AUXILIARY MUST mail MAY ( mailHomeDirectory $ mailAlias $ mailGroupMember $ mailUidNumber $ mailGidNumber $ mailEnabled $ mailQuota $ mailStorageDirectory ) )
olcObjectClasses: {1}( 1.3.6.1.4.1.29426.1.2.2.2 NAME 'PostfixBookMailForward' DESC 'Mail forward used in Postfix Book' SUP top AUXILIARY MUST ( mail $ mailAlias ) )
```
---

## ✅ Step 5: Create LDAP Users for Mail

In production, you'll probably want to use `ldif` files or a GUI like LDAP Account Manager to create full user entries with attributes like `mail`, `uid`, etc.

Create 01_mail-tree.ldif in docker-data/openldap/ldifs, a user should look like this in LDAP:

```ldif
# The root object of the tree, all entries will branch off this one:
dn: dc=gitcoins,dc=io
# DN is formed from `gitcoins.io` DNS labels:
# NOTE: This is just a common convention (not dependent on hostname or any external config)
objectClass: dcObject
# Must reference left most component:
dc: gitcoins
# It's required to use an `objectClass` that implements a "Structural Class":
objectClass: organization
# Value is purely descriptive, not important to tests:
o: DMS Test

# User accounts will belong to this subtree:
dn: ou=users,dc=gitcoins,dc=io
objectClass: organizationalUnit
ou: users
```

```ldif
# NOTE: A standard user account to test against
dn: uid=0x4477610799e7910f0e40f64da702aa9ffcf929ac,ou=users,dc=gitcoins,dc=io
objectClass: inetOrgPerson
objectClass: PostfixBookMailAccount
cn: 0x4477610799e7910f0e40f64da702aa9ffcf929ac
givenName: 0x4477610799e7910f0e40f64da702aa9ffcf929ac
surname: User
userID: 0x4477610799e7910f0e40f64da702aa9ffcf929ac
# Password is: secret
userPassword: {SSHA}eLtqGpid+hkSVhxvsdTPztv4uapRofGx
mail: 0x4477610799e7910f0e40f64da702aa9ffcf929ac@gitcoins.io
# postfix-book.schema:
mailAlias: postmaster2@gitcoins.io
mailGroupMember: employees@gitcoins.io
mailHomeDirectory: /var/mail/gitcoins.io/0x4477610799e7910f0e40f64da702aa9ffcf929ac/
mailStorageDirectory: maildir:/var/mail/gitcoins.io/0x4477610799e7910f0e40f64da702aa9ffcf929ac/
# postfix-book.schema generic options:
mailEnabled: TRUE
mailUidNumber: 5000
mailGidNumber: 5000
mailQuota: 10240
```

---

Let me know if you want to:
- Integrate **OAuth2 token-based login** with Dovecot
- Add a GUI (e.g. phpLDAPadmin or LDAP Account Manager)
- Auto-provision users from an external IdP

Want me to generate a working `docker-compose.override.yml` or full `ldif` for the LDAP users?