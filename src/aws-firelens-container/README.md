Customized 'aws-for-fluent-bit' docker image
============================================

This image modifies the
[aws-for-fluent-bit](https://github.com/aws/aws-for-fluent-bit) image which we
use to build a log forwarder "side car" container.  This container runs
fluent-bit and parses/forwards log events to to Opensearch.

Add your custom fluent-bit configurations to `fluent-bit_customizations.conf`.  This file 
gets applied as an `@INCLUDE` statement in `/fluent-bit/etc/fluent-bit.conf` during 
container initialization in ECS.

To update the image, run `src/aws-firelens-container/build_publish.sh`


Additional links of interest:

- https://docs.fluentbit.io/manual/about/what-is-fluent-bit
- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_firelens.html
- https://docs.aws.amazon.com/AmazonECS/latest/developerguide/firelens-taskdef.html
- https://github.com/aws-samples/amazon-ecs-firelens-examples/tree/mainline/examples/fluent-bit/amazon-opensearch-serverless
- https://docs.aws.amazon.com/AWSCloudFormation/latest/TemplateReference/aws-properties-ecs-taskdefinition-firelensconfiguration.html

