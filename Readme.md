# PGBackups Archive App

A very simple app to archive PGBackups to S3.

## Deployment

1. Click the button [![Deploy](https://www.herokucdn.com/deploy/button.png)](https://heroku.com/deploy)
2. Make sure web workers are scaled to 0
3. Add heroku scheduler
4. For each app you want to archive add a task to the scheduler

```bash
rake "backup[APP_NAME,OAUTH_TOKEN]"
```

An actual command for archiving "super-app" with OAuth token "e7dd6ad7-3c6a-411e-a2be-c9fe52ac7ed2"
would look like this:

```bash
rake "backup[super-app,e7dd6ad7-3c6a-411e-a2be-c9fe52ac7ed2]"
```

## Target app requirements

* The target app must have the PG Backups addon active.
* The following config variables need to be set on the target app

Required:

  * PGBACKUPS_AWS_ACCESS_KEY_ID
  * PGBACKUPS_AWS_SECRET_ACCESS_KEY
  * PGBACKUPS_BUCKET

Optional:

  * PGBACKUPS_REGION : default "us-east-1"
  * PGBACKUPS_DMS_URL : Ping this [Dead Man's Snitch](https://deadmanssnitch.com/) after successful backup

## How to generate a heroku OAuth Token

At the terminal on your computer

```bash
$ heroku plugins:install git@github.com:heroku/heroku-oauth.git
$ heroku authorizations:create -d "PG Backups Read" -s "read-protected"
Created OAuth authorization.
  ID:          2f01aac0-e9d3-4773-af4e-3e510aa006ca
  Description: PG Backups Read
  Scope:       read-protected
  Token:       e7dd6ad7-3c6a-411e-a2be-c9fe52ac7ed2
```

The `Token` is the OAuth token you need above

Be aware this token gives read access to all your apps.
I have contacted heroku about limiting the authorization to a specific app, but have yet to get a response.

## How to setup AWS access credentials

1. Create a S3 bucket, if you don't create the bucket in "US Standard" you will need to set PGBACKUPS_REGION according to the [S3 region codes](http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region)
2. Create an IAM user
3. Download the user credentials for use above
4. In the your new user's details click "Attach User Policy"
5. Choose "Custom Policy"
6. Set a meaningful policy name such as "PG Backups archive BUCKET_NAME"
7. Use this policy replacing "myapp-backups" with the bucket name you are using

```
{
  "Statement": [
    {
      "Action": "s3:*",
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::myapp-backups",
        "arn:aws:s3:::myapp-backups/*"
      ]
    }
  ]
}
```

This will give the user we just created complete access to only the bucket we just created.
