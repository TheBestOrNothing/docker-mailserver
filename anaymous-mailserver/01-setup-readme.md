# Docker Mailserver basic

## Configuration files required 
[Docker Mialserver info](https://docker-mailserver.github.io/docker-mailserver/latest/usage/#get-all-files)

 Download the basic files from docker-mailserver's github 

```bash
DMS_GITHUB_URL="https://raw.githubusercontent.com/docker-mailserver/docker-mailserver/master"
wget "${DMS_GITHUB_URL}/compose.yaml"
wget "${DMS_GITHUB_URL}/mailserver.env"
```
## :link: Links to Useful Resources

1. [FAQ](https://docker-mailserver.github.io/docker-mailserver/latest/faq/)
2. [Usage](https://docker-mailserver.github.io/docker-mailserver/latest/usage/)
3. [Examples](https://docker-mailserver.github.io/docker-mailserver/latest/examples/tutorials/basic-installation/)
4. [Issues and Contributing](https://docker-mailserver.github.io/docker-mailserver/latest/contributing/issues-and-pull-requests/)
5. [Release Notes](./CHANGELOG.md)
6. [Environment Variables](https://docker-mailserver.github.io/docker-mailserver/latest/config/environment/)
7. [Updating](https://docker-mailserver.github.io/docker-mailserver/latest/faq/#how-do-i-update-dms)

## :package: Included Services

- [Postfix](http://www.postfix.org) with SMTP or LDAP authentication and support for [extension delimiters](https://docker-mailserver.github.io/docker-mailserver/latest/config/account-management/overview/#aliases)
- [Dovecot](https://www.dovecot.org) with SASL, IMAP, POP3, LDAP, [basic Sieve support](https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/mail-sieve) and [quotas](https://docker-mailserver.github.io/docker-mailserver/latest/config/account-management/overview/#quotas)
- [Rspamd](https://rspamd.com/)
- [Amavis](https://www.amavis.org/)
- [SpamAssassin](http://spamassassin.apache.org/) supporting custom rules
- [ClamAV](https://www.clamav.net/) with automatic updates
- [OpenDKIM](http://www.opendkim.org) & [OpenDMARC](https://github.com/trusteddomainproject/OpenDMARC)
- [Fail2ban](https://www.fail2ban.org/wiki/index.php/Main_Page)
- [Fetchmail](http://www.fetchmail.info/fetchmail-man.html)
- [Getmail6](https://getmail6.org/documentation.html)
- [Postscreen](http://www.postfix.org/POSTSCREEN_README.html)
- [Postgrey](https://postgrey.schweikert.ch/)
- Support for [LetsEncrypt](https://letsencrypt.org/), manual and self-signed certificates
- A [setup script](https://docker-mailserver.github.io/docker-mailserver/latest/config/setup.sh) for easy configuration and maintenance
- SASLauthd with LDAP authentication
- OAuth2 authentication (_via `XOAUTH2` or `OAUTHBEARER` SASL mechanisms_)
