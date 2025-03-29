

## Configure Relay server 

The realy info is from mailgun

```
RELAY_USER=woofwoof@mail.gitcoins.io
RELAY_PASSWORD=XXXX-623424ea-d282f409
```

## Add user to ldap

The account alice and 0x4477... is created defaultly because lidf and schema files have been committed in the repository. The new user like 0x251a... authenticated by oidc.gitcoins.io can send mail well but can not receive the third party mail like wxxxfff@gmail, because the lua authentication let oauth2 bypass the userdb checking and when wxxxff@gmail send to  0x251a..@gitcoins.io, the ldap server can not find the 0x251a user, so delivery from gmail to gitcoins.io failed. So we must add the new user to ldap by command.

```
ldapadd -x -H ldap://ldap.gitcoins.io -D "cn=admin,dc=gitcoins,dc=io" -w adminpassword <<EOF
dn: uid=0x251aeaf02504f244f268d9886bee324e5cbb2bd6,ou=users,dc=gitcoins,dc=io
objectClass: inetOrgPerson
objectClass: PostfixBookMailAccount
cn: 0x251aeaf02504f244f268d9886bee324e5cbb2bd6
givenName: 0x251aeaf02504f244f268d9886bee324e5cbb2bd6
sn: User
uid: 0x251aeaf02504f244f268d9886bee324e5cbb2bd6
userPassword:: e1NTSEF9ZUx0cUdwaWQraGtTVmh4dnNkVFB6dHY0dWFwUm9mR3g=
mail: 0x251aeaf02504f244f268d9886bee324e5cbb2bd6@gitcoins.io
mailAlias: postmaster@gitcoins.io
mailGroupMember: employees@gitcoins.io
mailHomeDirectory: /var/mail/gitcoins.io/0x251aeaf02504f244f268d9886bee324e5cbb2bd6/
mailStorageDirectory: maildir:/var/mail/gitcoins.io/0x251aeaf02504f244f268d9886bee324e5cbb2bd6/
mailEnabled: TRUE
mailUidNumber: 5000
mailGidNumber: 5000
mailQuota: 10240
EOF
```

## Let's encryption limition

If you find there is no certs created for mail.gitcoins.io by acme-compenition, may the times of certs creation is limited. So you should copy all the history content in the docker-data/acme-companion to this new mail server.