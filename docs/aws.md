# AWS

## Local access to the RDS MySQL instance

You can use the helper script at `src/rds-port-forward.sh` to establish port forwarding through on of the deployed ECS containers. This will allow you to connect your local database tool (e.g. Sequel Pro) to the MySQL database.

To do this, you must:
- Have python3 installed (Recommend using pyenv for this)
- Have the cdl-ssm-utils utility app installed on your local machine ([See the documentaion here](https://github.com/cdlib/ias-user-guides/blob/main/SessionManager-for-Devs.md#automated-proxy-to-reach-an-rds-database))
- Be logged into AWS using SSO (make sure you're authenticated with the correct env)

Once you have all of the above requirements, you can run the script specifying the env and a local port to use.

```
> src/rds-port-forward.sh dev 3307

Note that you must be logged into the correct AWS environment!

When you see the 'Waiting for connections' message, you can switch to your
local database client (e.g. Sequel Pro) and connect to the database using:

   host: localhost
   database: dmptool
   port: 3307
   user: [username]
   password: [password]

Preparing to forward port 3307 to [RDS Host] on cluster [Cluster Name]

Select one of the Apollo containers when asked.
Multiple containers found in the cluster:
  1. taskdef-12345/nextJS
  2. taskdef-67890/shibboleth
  3. taskdef-98765/apolloServer
  4. taskdef-43210/nextJS
  5. taskdef-00000/apolloServer
Which one? 3
aws ssm start-session --profile [Profile Name] --target [Container Name] --document-name AWS-StartPortForwardingSessionToRemoteHost --parameters '{"host":["Rds Host"],"portNumber":["[Rds Port]"],"localPortNumber":["3307"]}'

Starting session with SessionId: [Session Id]
Port 3307 opened for sessionId [Session Id].
Waiting for connections...
```

The script will fetch the RDS username, password, and database name from SSM and display them for you so that you can paste them into your database tool.

When it asks which continer to use, select one of the `apolloServer` containers because it has permission to access RDS.

When you see the `Waiting for connections...` message, it is ready for you to connect to in your database tool.