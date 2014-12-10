# PGBackups Archive App

A very simple app to archive PGBackups to S3.

## Deployment

1. Click the button [![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)

2. Scale web workers to 0

3. Add heroku scheduler

4. For each app you want to archive add a task as follows

```bash
OAUTH_TOKEN=e7dd6ad7-3c6a-411e-a2be-c9fe52ac7ed2 APP_NAME=super-app rake run_backup
```

## Generate the OAuth Token

```bash
$ heroku plugins:install git@github.com:heroku/heroku-oauth.git
$ heroku authorizations:create -d "PG Backups Read" -s "read-protected"
Created OAuth authorization.
  ID:          2f01aac0-e9d3-4773-af4e-3e510aa006ca
  Description: PG Backups Read
  Scope:       read-protected
  Token:       e7dd6ad7-3c6a-411e-a2be-c9fe52ac7ed2
```

Use the `Token`
