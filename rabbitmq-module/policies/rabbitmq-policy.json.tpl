{
  "vhosts": [
    {
      "name": "/"
    }
  ],
  "users": [
    {
      "name": "${admin_user}",
      "password_hash": "${admin_password_hash}",
      "tags": "administrator"
    }
  ],
  "permissions": [
    {
      "user": "${admin_user}",
      "vhost": "/",
      "configure": ".*",
      "write": ".*",
      "read": ".*"
    }
  ],
  "policies": [
    {
      "name": "ha-all",
      "pattern": ".*",
      "vhost": "/",
      "definition": {
        "ha-mode": "all",
        "ha-sync-mode": "automatic"
      }
    }
  ]
}