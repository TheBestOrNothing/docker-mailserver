<?php
  $config['imap_auth_type'] = 'PLAIN';
  $config['smtp_user'] = '%u';
  $config['smtp_pass'] = '%p';
  $config['oauth_provider'] = 'generic';
  $config['oauth_provider_name'] = 'MetaMask';
  $config['oauth_client_id'] = 'oidcCLIENT';
  $config['oauth_client_secret'] = 'oidcSECRET';
  $config['oauth_auth_uri'] = 'https://oidc.coinsgpt.io/auth';
  $config['oauth_token_uri'] = 'https://oidc.coinsgpt.io/token';
  $config['oauth_identity_uri'] = 'https://oidc.coinsgpt.io/me';

  // Optional: disable SSL certificate check on HTTP requests to OAuth server. For possible values, see:
  // http://docs.guzzlephp.org/en/stable/request-options.html#verify
  $config['oauth_verify_peer'] = false;

  $config['oauth_scope'] = 'email openid profile';
  $config['oauth_identity_fields'] = ['email'];

  // Boolean: automatically redirect to OAuth login when opening Roundcube without a valid session
  $config['oauth_login_redirect'] = false;
