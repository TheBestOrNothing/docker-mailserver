## Introduction

Dovecot has the ability to let users create their own custom user provisioning and authentication providers in https://docker-mailserver.github.io/docker-mailserver/latest/examples/use-cases/auth-lua/ . This allows any data source that can be approached from Lua to be used for authentication, including web servers. It is possible to do more with Dovecot and Lua, but other use cases fall outside of the scope of this documentation page.

```
Dovecot authentication via Lua scripting is not officially supported in DMS. No assistance will be provided should you encounter any issues.

DMS provides the required packages to support this guide. Note that these packages will be removed should they introduce any future maintenance burden.

The example in this guide relies on the current way in which DMS works with Dovecot configuration files. Changes to this to accommodate new authentication methods such as OpenID Connect will likely break this example in the future. This guide is updated on a best-effort base.
```

Dovecot's Lua support can be used for user provisioning (userdb functionality) and/or password verification (passdb functionality). Consider using other userdb and passdb options before considering Lua, since Lua does require the use of additional (unsupported) program code that might require maintenance when updating DMS.

Each implementation of Lua-based authentication is custom. Therefore it is impossible to write documentation that covers every scenario. Instead, this page describes a single example scenario. If that scenario is followed, you will learn vital aspects that are necessary to kickstart your own Lua development:

- How to override Dovecot's default configuration to disable parts that conflict with your scenario.
- How to make Dovecot use your Lua script.
- How to add your own Lua script and any libraries it uses.
- How to debug your Lua script.


## Modify Dovecot's configuration

???+ example "Add to DMS volumes in `compose.yaml`"

    ```yaml
        # All new volumes are marked :ro to configure them as read-only, since their contents are not changed from inside the container
        volumes:
          # Configuration override to disable LDAP authentication
          - ./docker-data/dms/config/dovecot/auth-ldap.conf.ext:/etc/dovecot/conf.d/auth-ldap.conf.ext:ro
          # Configuration addition to enable Lua authentication
          - ./docker-data/dms/config/dovecot/auth-lua-httpbasic.conf:/etc/dovecot/conf.d/auth-lua-httpbasic.conf:ro
          # Directory containing Lua scripts
          - ./docker-data/dms/config/dovecot/lua/:/etc/dovecot/lua/:ro
    ```

Create a directory for Lua scripts:
```bash
mkdir -p ./docker-data/dms/config/dovecot/lua
```

Create configuration file `./docker-data/dms/config/dovecot/auth-ldap.conf.ext` for LDAP user provisioning:
```
userdb {
  driver = ldap
  args = /etc/dovecot/dovecot-ldap.conf.ext
}
```

Create configuration file `./docker-data/dms/config/dovecot/auth-lua-httpbasic.conf` for Lua user authentication:
```
passdb {
  driver = lua
  args = file=/etc/dovecot/lua/auth-httpbasic.lua blocking=yes
}
```

That is all for configuring Dovecot.

## Create the Lua script

Create Lua file `./docker-data/dms/config/dovecot/lua/auth-httpbasic.lua` with contents:

```lua
local http_url = "https://nextcloud.example.com/remote.php/dav/"
local http_method = "PROPFIND"
local http_status_ok = 207
local http_status_failure = 401
local http_header_forwarded_for = "X-Forwarded-For"

package.path = package.path .. ";/etc/dovecot/lua/?.lua"
local base64 = require("base64")

local http_client = dovecot.http.client {
  timeout = 1000;
  max_attempts = 1;
  debug = false;
}

function script_init()
  return 0
end

function script_deinit()
end

function auth_passdb_lookup(req)
  local auth_request = http_client:request {
    url = http_url;
    method = http_method;
  }
  auth_request:add_header("Authorization", "Basic " .. (base64.encode(req.user .. ":" .. req.password)))
  auth_request:add_header(http_header_forwarded_for, req.remote_ip)
  local auth_response = auth_request:submit()
  local resp_status = auth_response:status()
  local reason = auth_response:reason()

  local returnStatus = dovecot.auth.PASSDB_RESULT_INTERNAL_FAILURE
  local returnDesc = http_method .. " - " .. http_url .. " - " .. resp_status .. " " .. reason
  if resp_status == http_status_ok
  then
    returnStatus = dovecot.auth.PASSDB_RESULT_OK
    returnDesc = "nopassword=y"
  elseif resp_status == http_status_failure
  then
    returnStatus = dovecot.auth.PASSDB_RESULT_PASSWORD_MISMATCH
    returnDesc = ""
  end
  return returnStatus, returnDesc
end
```

Replace the hostname in the URL to the actual hostname of Nextcloud.

Dovecot [provides an HTTP client for use in Lua](https://doc.dovecot.org/admin_manual/lua/#dovecot.http.client). Aside of that, Lua by itself is pretty barebones. It chooses library compactness over included functionality. You can see that in that a separate library is referenced to add support for Base64 encoding, which is required for [HTTP basic access authentication](https://en.wikipedia.org/wiki/Basic_access_authentication). This library (also a Lua script) is not included. It must be downloaded and stored in the same directory:

```bash
cd ./docker-data/dms/config/dovecot/lua
curl -JLO https://raw.githubusercontent.com/iskolbin/lbase64/master/base64.lua
```

Only use native (pure Lua) libraries as dependencies if possible, such as `base64.lua` from the example. This ensures maximum compatibility. Performance is less of an issue since Lua scripts written for Dovecot probably won't be long or complex, and there won't be a lot of data processing by Lua itself.

## Debugging a Lua script

To see which Lua version is used by Dovecot if you plan to do something that is version dependent, run:

```bash
docker exec CONTAINER_NAME strings /usr/lib/dovecot/libdovecot-lua.so|grep '^LUA_'
```

While Dovecot logs the status of authentication attempts for any passdb backend, Dovecot will also log Lua scripting errors and messages sent to Dovecot's [Lua API log functions](https://doc.dovecot.org/admin_manual/lua/#dovecot.i_debug). The combined DMS log (including that of Dovecot) can be viewed using `docker logs CONTAINER_NAME`. If the log is too noisy (_due to other processes in the container also logging to it_), `docker exec CONTAINER_NAME cat /var/log/mail/mail.log` can be used to view the log of Dovecot and Postfix specifically.

If working with HTTP in Lua, setting `debug = true;` when initiating `dovecot.http.client` will create debug log messages for every HTTP request and response.