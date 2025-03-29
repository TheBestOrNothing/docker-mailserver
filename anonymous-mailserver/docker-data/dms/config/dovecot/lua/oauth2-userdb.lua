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