# syntax = docker/dockerfile:1

FROM public.ecr.aws/aws-observability/aws-for-fluent-bit:stable

RUN yum update

COPY ./fluent-bit.conf /fluent-bit/etc/

