Let's Encrypt has a rate limit, error log:

```
ginx-proxy-acme  | Creating/renewal mail.gitcoins.io certificates... (mail.gitcoins.io)
nginx-proxy-acme  | [Wed Mar 26 06:33:11 UTC 2025] Using CA: https://acme-v02.api.letsencrypt.org/directory
nginx-proxy-acme  | [Wed Mar 26 06:33:11 UTC 2025] Creating domain key
nginx-proxy-acme  | [Wed Mar 26 06:33:11 UTC 2025] The domain key is here: /etc/acme.sh/alice@gitcoins.io/mail.gitcoins.io/mail.gitcoins.io.key
nginx-proxy-acme  | [Wed Mar 26 06:33:11 UTC 2025] Generating next pre-generate key.
nginx-proxy-acme  | [Wed Mar 26 06:33:13 UTC 2025] Single domain='mail.gitcoins.io'
nginx-proxy-acme  | [Wed Mar 26 06:33:14 UTC 2025] Error creating new order. Le_OrderFinalize not found. {
nginx-proxy-acme  |   "type": "urn:ietf:params:acme:error:rateLimited",
nginx-proxy-acme  |   "detail": "too many certificates (5) already issued for this exact set of domains in the last 168h0m0s, retry after 2025-03-26 13:10:39 UTC: see https://letsencrypt.org/docs/rate-limits/#new-certificates-per-exact-set-of-hostnames",
nginx-proxy-acme  |   "status": 429
nginx-proxy-acme  | }
nginx-proxy-acme  | [Wed Mar 26 06:33:14 UTC 2025] Please check log file for more details: /dev/null
```


This error happens because **Let's Encrypt has a rate limit** on how many certificates you can issue for **the exact same domain (or set of domains)** in a rolling 7-day (168 hours) period.

---

### 🔍 Error Explanation:
```
"type": "urn:ietf:params:acme:error:rateLimited",
"detail": "too many certificates (5) already issued for this exact set of domains in the last 168h0m0s"
```

This means:

- You've already issued **5 certificates** for `mail.gitcoins.io` in the past 7 days.
- You're hitting the [rate limit for "Certificates per Exact Domain"](https://letsencrypt.org/docs/rate-limits/#duplicate-certificate-limit).

---

### ✅ What You Can Do:

1. **Wait until the rate limit resets.**
   - In your logs:  
     ```
     retry after 2025-03-26 13:10:39 UTC
     ```

2. **Avoid unnecessary re-issuance.**
   - Ensure your setup isn't reissuing certs too often (e.g., restarting `acme-companion` or changing labels on containers).

3. **Test with Staging first.**
   - Use Let's Encrypt's **staging endpoint** during testing to avoid production rate limits:
     ```yaml
     environment:
       ACME_CA_URI: https://acme-staging-v02.api.letsencrypt.org/directory
     ```
   - Swap back to production once you're confident.

4. **Check existing valid certs.**
   - You might already have valid certs that `nginx-proxy` could reuse.
   - Check `/etc/acme.sh/alice@gitcoins.io/mail.gitcoins.io/` inside your `nginx-proxy-acme` volume.

---

### 💡 Bonus Tip:
You can view your domain's cert issuance history here:  
🔗 https://crt.sh/?q=mail.gitcoins.io

---

Want help checking what’s causing the multiple requests, or improving your `docker-compose` setup to avoid this?