function script_init()
    return 0
end

function script_deinit()
end

function auth_userdb_lookup(req)
    print("UserDB lookup triggered")
    print("Username: " .. req.username)

    local email = req.username
    local password = "StrongPassword123"  -- Insecure: static password

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
