# syntax = docker/dockerfile:1

FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:stable

RUN yum -y update

COPY ./dmp_customizations.conf /fluent-bit/etc/
