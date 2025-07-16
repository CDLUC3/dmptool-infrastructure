# syntax = docker/dockerfile:1

FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:stable

RUN yum -y update

COPY ./fluent-bit.dmp_custom_filters.include /fluent-bit/config/fluent-bit.dmp_custom_filters.include
