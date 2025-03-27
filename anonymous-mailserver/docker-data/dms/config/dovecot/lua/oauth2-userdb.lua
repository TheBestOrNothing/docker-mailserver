local apikey = "apikeyhere"
local http_url = "https://authentik.company/api/v3/core/users/"
local http_method = "GET"

function script_init()
    return 0
end

function script_deinit()
end

function auth_userdb_lookup(req)
    print("This is a log message")
    print(req.username)
    return dovecot.auth.USERDB_RESULT_OK, "uid=5000 gid=5000 home=/var/mail/coinsgpt" .. req.username .. "mail=maildir:~/Maildir"
end
