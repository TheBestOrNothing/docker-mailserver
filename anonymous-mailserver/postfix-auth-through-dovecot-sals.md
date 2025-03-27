
Based on the Dovecot documentation https://doc.dovecot.org/2.3/configuration_manual/howto/postfix_and_dovecot_sasl/, here's how to configure Postfix to use Dovecot's SASL authentication:

# Configuring Postfix Authentication with Dovecot SASL in docker-mailserver

To configure Postfix to use Dovecot's SASL authentication in the [docker-mailserver](https://github.com/docker-mailserver/docker-mailserver) container, please follow these steps based on the Dovecot documentation:

## Lookup Dovecot for SASL Authentication

1. First, ensure Dovecot is configured to provide SASL authentication by adding/modifying these settings in your `config/dovecot/conf.d/10-master.conf` (or appropriate config file in your docker-mailserver setup):

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

2. Make sure the Postfix to use Dovecot authentication
- smtpd_sasl_type=dovecot
- smtpd_sasl_path equal to the unix_listener in the service auth like /dev/shm/sasl-auth.sock:

```bash
docker exec -it mailserver postconf -f | grep smtpd_sasl_type
docker exec -it mailserver postconf -f | grep smtpd_sasl_path
```

## How to enable Postfix auth through dovecot's SALS in Docker mail

1. To overwrite the configuraiton of postfix https://docker-mailserver.github.io/docker-mailserver/latest/config/advanced/override-defaults/postfix/

Add these settings to your Postfix configuration (typically in `docker-data/dms/config/postfix-main.cf`):

```
smtpd_sasl_type = dovecot

# Can be an absolute path, or relative to $queue_directory
# Debian/Ubuntu users: Postfix is setup by default to run chrooted, so it is best to leave it as-is below
# smtpd_sasl_path = private/auth
smtpd_sasl_path = /dev/shm/sasl-auth.sock

# On Debian Wheezy path must be relative and queue_directory defined
#queue_directory = /var/spool/postfix

# and the common settings to enable SASL:
smtpd_sasl_auth_enable = yes
# With Postfix version before 2.10, use smtpd_recipient_restrictions
smtpd_relay_restrictions = permit_mynetworks, permit_sasl_authenticated, reject_unauth_destination
```

2. Mounts the configuration file to docker-mailserver

```yaml
services:
  mailserver:
    image: docker.io/mailserver/docker-mailserver:latest
    volumes:
      - ./docker-data/dms/config/:/tmp/docker-mailserver/
    # ... other configurations
```

## Verification

To verify the configuration is working:

1. Check Postfix logs for SASL support:
   ```bash
   docker exec -it mailserver postconf -n | grep sasl
   ```

2. Test SMTP authentication:
   ```bash
   openssl s_client -connect mail.gitcoins.io:465 -quiet
   EHLO gitcoins.io
   ```

You should see `AUTH PLAIN LOGIN` in the supported capabilities.

This configuration allows Postfix to delegate authentication to Dovecot while maintaining the security and simplicity of the docker-mailserver setup.