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
- `aws ssm put-parameter --name /uc3/dmp/HostedZoneId --value [HOSTED_ZONE_ID] --type String`

Note we explicitly do NOT use the "overwrite" argument for global variables because they may be used by other services. By NOT overwiting them, we ensure that they are not accidentally overwritten and impact other systems.

You need to initialize the following env variables that are specific to the DMP Tool:
- Database Password: `aws ssm put-parameter --name /uc3/dmp/tool/[ENV]/DbPassword --value [PASSWORD] --type SecureString --overwrite`
- The default [ROR](https://ror.org) (your organization): `aws ssm put-parameter --name /uc3/dmp/tool/[ENV]/DefaultAffiliationId --value [ROR ID] --type String --overwrite`

### Sceptre (WIP)

- Create the Codestar Connection to GitHub
  - Run the Sceptre script to create the resource: `sceptre launch codestar-connection.yaml`
  - Login to the AWS console and navigate to the CodePipeline page
  - Go to Settings > Connections and select the new connection
  - Follow the OAuth instructions to authorize the connection
-
-
- ecr
- route53
- ecs-cluster

## Documentation

Additional documentation can be found in the `docs/` directory.

- Files in the `*.epgz` were built using the [Pencil Project](https://pencil.evolus.vn). The corresponding `*.png` versions of the files were exported from that tool.
