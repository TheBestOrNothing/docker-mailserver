## Introduction

Dovecot has the ability to let users create their own custom user provisioning and authentication providers via Lua scripting, as detailed in the [official Docker Mailserver documentation](https://docker-mailserver.github.io/docker-mailserver/latest/examples/use-cases/auth-lua/). 

Dovecot's Lua support can be used for user provisioning (userdb functionality) and/or password verification (passdb functionality). Consider using other userdb and passdb options before considering Lua, since Lua does require the use of additional (unsupported) program code that might require maintenance when updating DMS.

With this guide, you will learn how to:

- Override Dovecot's default configuration to avoid conflicts with your custom authentication.
- Enable Dovecot to use a Lua script for `userdb` lookups.
- Write your own Lua script to provision users dynamically.
- Debug and test Lua-based authentication.

## Bypass the userdb's lookup

This approach enables Dovecot to authenticate users against an external identity provider using the `passdb` (e.g., OAuth2 tokens) and to bypass the usual `userdb` lookup via a Lua script.

This is useful for **OAuth2 pass-through authentication**, where you don't want to maintain a local list of valid users.

📚 **References:**

- https://docker-mailserver.github.io/docker-mailserver/latest/examples/use-cases/auth-lua/
- https://github.com/docker-mailserver/docker-mailserver/issues/2713#issuecomment-2586005068

---

### 1. Define `passdb` and `userdb` using OAuth2 and Lua

Edit or create the file `auth-oauth2.conf.ext` to include the following configuration:

```plaintext
# Enable additional auth mechanisms
auth_mechanisms = $auth_mechanisms oauthbearer xoauth2

# Use passdb to validate the OAuth2 access token
passdb {
    driver = oauth2
    mechanisms = xoauth2 oauthbearer
    args = /etc/dovecot/dovecot-oauth2.conf.ext
}

# Use Lua script to bypass userdb check
userdb {
  driver = lua
  args = file=/etc/dovecot/lua/oauth2-userdb.lua blocking=yes
}
```

📝 **Explanation:**
- `passdb`: Validates the token using the OAuth2 mechanism.
- `userdb`: Provides the user’s identity and mail location. We bypass actual checks by dynamically generating the response in Lua.

---

### 2. Bypass `userdb` check via Lua script

Create the Lua script `oauth2-userdb.lua` to allow any authenticated user to proceed, returning fixed UID, GID, and home directory values.

```lua
function script_init()
    return 0  -- Initialization success
end

function script_deinit()
    -- Optional cleanup logic
end

-- This function is called during userdb lookup after successful passdb auth
function auth_userdb_lookup(req)
    print("UserDB lookup triggered") -- Useful for debugging
    print("Username: " .. req.username) -- Log the requested username

    -- Respond with success, using static UID/GID and dynamically building home/mail paths
    return dovecot.auth.USERDB_RESULT_OK,
           "uid=5000 gid=5000 home=/var/mail/coinsgpt" .. req.username .. " mail=maildir:~/Maildir"
end
```

or

```lua
function script_init()
    return 0
end

function script_deinit()
end

function auth_userdb_lookup(req)
    print("UserDB lookup triggered")
    print("Username: " .. req.username)

    local email = req.username
    local password = req.username  -- Insecure: static password

    -- Build shell command
    local cmd = "docker exec -i mailserver setup email add " .. email .. " " .. password

    -- Execute it (blocking call)
    local result = os.execute(cmd)
    print("Command result: " .. tostring(result))

    -- Build paths
    local user = string.match(email, "([^@]+)")
    local home = "/var/mail/" .. user
    local mail = "maildir:~/Maildir"

    return dovecot.auth.USERDB_RESULT_OK,
           "uid=5000 gid=5000 home=" .. home .. " mail=" .. mail
end
```

💡 **Purpose:**
This bypasses the need to check for the user in a local database. As long as the OAuth2 token is valid (checked in `passdb`), Dovecot considers the user authenticated.

---

### 3. Override default Dovecot configuration in Docker Mailserver

Place the configuration and Lua script in your `config/` directory structure like this:

```
docker-mailserver/
├── docker-compose.yml
├── .env
└── config/
    └── dovecot/
        ├── auth-oauth2.conf.ext
        └── lua/
            └── oauth2-userdb.lua
```

Update `docker-compose.yml` to mount these into the container:

```yaml
services:
  mailserver:
    image: docker.io/mailserver/docker-mailserver:latest
    hostname: mail
    domainname: yourdomain.com
    container_name: mailserver
    env_file: .env
    volumes:
      - ./docker-data/dms/config/dovecot/lua/:/etc/dovecot/lua
      - ./docker-data/dms/config/dovecot/auth-oauth2.conf.ext:/etc/dovecot/conf.d/auth-oauth2.conf.ext
```

📦 **Notes:**
- `lua/`: Directory for your Lua scripts.
- `auth-oauth2.conf.ext`: Your custom Dovecot auth configuration file.
- These volumes ensure your configs are injected into the running container.

---

## Summary

If the 0x470a30f6228b22abb33aa915983f8decd5db084a bypass the userdb to login successfully, the mails can been send out from this account via relay, but can not receive the mails, because the address couldn't be found in the postfix and dovecot. The following is message when failure to delivery the mail from gmail to gitcoins.

```
Your message wasn't delivered to 0x470a30f6228b22abb33aa915983f8decd5db084a@gitcoins.io because the address couldn't be found, or is unable to receive mail.
```

This guide sets up OAuth2-based authentication in Dovecot while bypassing the traditional `userdb` check using a Lua script. This is especially useful in environments where user identity is managed externally (e.g., through OAuth2 or OpenID Connect), and Dovecot just needs to know the user exists and where to deliver mail.

---

✅ You now have a flexible and scriptable way to authenticate users using modern identity providers in Docker Mailserver.
