# syntax = docker/dockerfile:1

FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:stable

RUN yum -y update

COPY ./fluent-bit.conf.include /fluent-bit/config/fluent-bit.conf.include

