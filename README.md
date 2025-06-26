# DMP Tool - infrastructure as code

This the Amazon Web Services (AWS) infrastructure for the DMP Tool system.

<img src="docs/architecture-diagram.png?raw=true">

**Please note that you must have an AWS account to run this code and that building the system will create resources in your account that may incur charges!**

We use [AWS CloudFormation](https://aws.amazon.com/cloudformation/) templates to create resources within the AWS cloud environment and [Sceptre](https://docs.sceptre-project.org/3.2.0/) to orchestrate the Cloud Formation stacks.

## Directory layout

Sceptre structures your code into two primary folders: `config` and `templates`

```
  config
  |  |
  |   ----- config.yaml                   # Base Sceptre config
  |  |
  |   ----- [env]                         # Sceptre configs by Environment
  |            |
  |             ----- *.yaml              # Configuration for individual AWS Resource types
  |            |
  |             ----- config.yaml         # Global configuration that applies to all other files in the dir
  |
  templates                               # The Cloud Formation templates
  |
  docs                                    # Diagrams and documentation
  |
  scripts                                 # Various helper scripts

```

## Notes about Sceptre

### Installation
Run the following command to install Sceptre:
```bash
pip install sceptre sceptre-ssm-resolver
```

### Referencing variables

Sceptre allows you to reference variables in several ways. Note that you can use many of these within `config.yaml` files as well.

#### Hard-coding:
You can hard code values directly in a config. For example: `S3Versioning: Enabled`

#### Through Sceptre configuration files
You can also add values to the Sceptre user data section of a `config.yaml`. For example:
```
sceptre_user_data:
  env: development
```
Which can then be referenced in your config file as `Env: !stack_attr sceptre_user_data.env`

#### Through SSM parameters
You can have Sceptre fetch SSM parameters and plug the resulting value into your config file. For example: `DbMasterPassword: !ssm /uc3/dmp/tool/stg/DbPassword`

#### Through Cloud Formation stack outputs
You can also reference the stack outputs from other CF stacks. You can do this for CF stacks managed within your project or ones created elsewhere (must be in the same region and same account). For example:
```
# Reference the ECR ARN that was created within the same Sceptre project:
EcrRepositoryArn: !stack_output tool/stg/ecr.yaml::EcrRepositoryARN

# Reference the VPC ID that was created outside our Sceptre project:
vpc_id: !stack_output_external cdl-uc3-prd-vpc-stack::vpc
```

### Orchestration
Sceptre helps orchestrate dependencies between resources. It examines the yaml config file you are attempting to run and ensures that any references to resources defined in other config files are available.

For example, the `stg/s3-private.yaml` references the S3 bucket id for our log bucket, `S3LogBucket: !stack_output tool/stg/s3-logs.yaml::S3BucketID`. When you run a sceptre command to create/update the S3 private bucket, Sceptre will first create/update the S3 log bucket.

### S3 bucket
Sceptre will automatically create an S3 bucket to store the compiled Cloud Formation templates that it runs. The name of the bucket is defined in `config/config.yaml`

### Config files
Each directory under `config/` must have its own `config.yaml`. The values in these files cascade much like CSS files. So, if you define `region: us-west-2` in `config/config.yaml` and then define `region: us-east-1` in `config/global/config.yaml` then the following would happen:
- Running `sceptre create config/global/cert.yaml` would create resources in the `us-east-1` region
- Running `sceptre create config/stg/cert.yaml` would create resources in the `us-west-2` region

### Naming conventions
Unless the resource in the Cloud Formation template specifies a specific name, Sceptre will automatically
create a unique name for the resource. It does this in the following way:
```
 dmptool-stg-codebuild-nextJs-CodeBuildProject-3487y23t8
     ^    ^         ^                ^             ^
     |    |         |                |             |
     |    |         |                |              ----- random value created by Sceptre
     |    |         |                |
     |    |         |                 ------- derived from the name of the resource in the CF template
     |    |         |
     |    |          --------- derived from the name of the file that is being run
     |    |
     |     ------------ derived from the name of the directory the files live in
     |
      -------------- derived from the `project-code` value defined in `config/config.yaml
```

### Tags
If you define `stack_tags` in your `config.yaml` file, Sceptre will automatically apply them to any resource that allows it.

### Creating, Updating or Deleting AWS Resources

To create or update stacks simply run `sceptre launch path/to/resource-config.yaml` where `path/to/resource-config.yaml` is the location of the Sceptre config file you want to create or update. Sceptre will handle creating and updating any related resources.

To delete a stack run `sceptre delete path/to/resource-config.yaml` where `path/to/resource-config.yaml` is the location of the Sceptre config file you want to create or update. Sceptre will delete any related stacks for you. For example if you delete the S3 bucket that acts as the origin for the CloudFront distribution, Sceptre will delete the CloudFront distribution, its web application firewall (WAF) and Certificate.

## Building a new environment

This repository uses [Sceptre](https://docs.sceptre-project.org/3.2.0/) to orchestrate the creation of the entire system. See above for notes about Sceptre if this is your first time using this technology.

### SSM variable setup (WIP)

You need to initialize the following global variables in SSM:
- AWS SES: `aws ssm put-parameter --name /uc3/[ENV]/SesEndpoint --value [SES_ENDPOINT] --type String`
- AWS SES Bounced Email Bucket: `aws ssm put-parameter --name /uc3/[ENV]/SesBouncedEmailBucket --value [S3BucketId] --type String`

Note we explicitly do NOT use the "overwrite" argument for global variables because they may be used by other services. By NOT overwiting them, we ensure that they are not accidentally overwritten and impact other systems.

You need to initialize the following env variables that are specific to the DMP Tool:
- Helpdesk Email: `aws ssm put-parameter --name /uc3/dmp/tool/[ENV]/HelpdeskEmail --value [EMAIL] --type String --overwrite`
- Database Password: `aws ssm put-parameter --name /uc3/dmp/tool/[ENV]/RdsPassword --value [PASSWORD] --type SecureString --overwrite`
- The default EZID shoulder that will be used to register DOIs: `aws ssm put-parameter --name /uc3/dmp/tool/[ENV]/EzidShoulder --value [Shoulder ID] --type String --overwrite`
- AWS SES Access Key Id: `aws ssm put-parameter --name /uc3/dmp/tool/[env]/SesAccessKeyId --value [MyKey] --type SecureString --overwrite`
- AWS SES Access Key Secret: `aws ssm put-parameter --name /uc3/dmp/tool/[env]/SesAccessKeySecret --value [MySecret] --type SecureString --overwrite`
- Bcrypt Secret: `aws ssm put-parameter --name /uc3/dmp/tool/[env]/BcryptHashSecret --value [Secret] --type SecureString --overwrite`
- Cache Token Secret: `aws ssm put-parameter --name /uc3/dmp/tool/[env]/CacheHashSecret --value [Secret] --type SecureString --overwrite`
- JWT Secret: `aws ssm put-parameter --name /uc3/dmp/tool/[env]/JWTSecret --value [Secret] --type SecureString --overwrite`
- Refresh Token Secret: `aws ssm put-parameter --name /uc3/dmp/tool/[env]/JWTRefreshSecret --value [Secret] --type SecureString --overwrite`

### DMPHub client credentials

You will need to ensure that credentials have been defined in the DMPHub system.

**If you are building the system within our UC3 account**
The owner of the DMPHub system will provide you with the CF stack name and output variables for your ClientId and Client Secret that will need to be used within the `config/[env]/ecs-apollo.yaml` Sceptre config file. For example:
`DmpHubClientId: !stack_output_external uc3-dmp-hub-stg-regional-api-clients-dmp-tool-apollo::ClientId`

**If you are not working within the UC3 account**
The owner of the DMPHub system will provide you with your ClientId and ClientSecret. You should then use AWS CLI commands like the ones above to store those values in the SSM paramater store. Then update the `config/[env]/ecs-apollo.yaml` Sceptre config file to reference yoour new variables. For example: `DmpHubClientId: !ssm /name/of/my/DMPHubClientId`

You should always store the `DMPHubClientSecret` in SSM and then access like this in yhe sceptre config: `DmpHubClientSecret: !ssm /name/of/my/DMPHubClientSecret`

### Sceptre (WIP)

Once your SSM parameters have been set up, you can build out the AWS resources.

1. Create the Codestar Connection to GitHub (required to run the CodePipelines)
  - Run `sceptre launch [env]/codestar.yaml`
  - Login to the AWS console and navigate to the CodePipeline page
  - Go to Settings > Connections and select the new connection
  - Follow the OAuth instructions to authorize the connection
2. Create the backend Apollo Server
  - Run `sceptre launch [env]/codepipeline/apollo.yaml`
3. Create the frontend NextJS Server
  - Run `sceptre launch [env]/codepipeline/nextJS.yaml`
4. Coming Soon! - Create the shibboleth Server
  - Run `sceptre launch [env]/codepipeline/shibboleth.yaml`
5. Stage/Prod only - Create your Backup Vault.
  - The RDS database and DynamoDB table are backed up automatically. The content of the S3 buckets is not though, so run `sceptre launch [env]/backup-vault.yaml` to ensure that the CloudFront and private buckets get backed up

### Initialize DynamoDB

If the system has any plans in the MySQL database, then you will need to login to the UI as a super admin user and then run the following GraphQL mutation to generate an initial version for each plan. Once you have logged in, navigate to the Apollo Server Explorer at `https://[my-domain]/graphql` and run the following mutation:
```
mutation SuperInitializePlanVersions {
  superInitializePlanVersions {
    count
    planIds
  }
}
```

### Verify the systems are online
Once the CloudFormation stacks have completed, you can do the following to determine if the systems are up and running.
- Navigate to `https://[domain-name]/graphql` if the page loads then the backend Apollo Server is online
- Navigate to `https://[domain-name]` if the page loads then the frontend NextJS Server is online
- Click "Login" on `https://[domain-name]` and sign in with an account that uses email+password (instead of SSO). If you are able to sign in, then the frontend and backend are communicating properly
- Coming Soon! - Click "Login" on `https://[domain-name]` and sign in with an account that uses SSO. If you are redirected to the IdP, can sign in, and get redirected back to the application and are signed in then Shibboleth is operating normally.

## Documentation

Additional documentation can be found in the `docs/` directory.

- Files in the `*.epgz` were built using the [Pencil Project](https://pencil.evolus.vn). The corresponding `*.png` versions of the files were exported from that tool.
