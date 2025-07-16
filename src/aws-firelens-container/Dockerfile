# syntax = docker/dockerfile:1

FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:stable

RUN yum -y update

COPY ./fluent-bit.conf.custom /fluent-bit/etc/fluent-bit.conf.custom

