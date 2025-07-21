# syntax = docker/dockerfile:1

FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:stable

## Optional - add python tool for debugging opensearch ingestion issues
#RUN yum install python3
#RUN pip3 install boto3 opensearch-py
#RUN [ -d /local/bin ] || mkdir /local/bin
#COPY ./aoss_ingest_tester.py /local/bin/

# add custom filters for fluent-bit
RUN yum -y update
COPY ./fluent-bit_customizations.conf /fluent-bit/etc/
