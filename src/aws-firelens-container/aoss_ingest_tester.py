# /usr/bin/env python3
# python script for validating your log-router container can properly ingest content
# into your AOSS collection.
#
# Prerequisites for use on `aws-for-fluent-bit` based container images:
#   yum install python3
#   pip3 install boto3 opensearch-py

from opensearchpy import OpenSearch, RequestsHttpConnection, AWSV4SignerAuth
from opensearchpy.helpers import bulk
import boto3

# serverless collection endpoint, without https://
#
# dmp-log-collection
#host = 'zywkyz0ukbvv05v62tnl.us-west-2.aoss.amazonaws.com'
#
# mrt-log-collection
host = 'ugbu3b4vhoqcrtwbsypk.us-west-2.aoss.amazonaws.com'  # serverless collection endpoint, without https://

region = 'us-west-2'  # e.g. us-east-1
service = 'aoss'
credentials = boto3.Session().get_credentials()
auth = AWSV4SignerAuth(credentials, region, service)

# create an opensearch client and use the request-signer
client = OpenSearch(
    hosts=[{'host': host, 'port': 443}],
    http_auth=auth,
    use_ssl=True,
    verify_certs=True,
    connection_class=RequestsHttpConnection,
    pool_maxsize=20,
)


## create an index
index_name = 'my_new_index'
print('\nCreating index:')
try:
  create_response = client.indices.create(
      index_name
  )
except Exception as e:
  print("Create index failed:")
  print(e)
else:
  print(create_response)


# index a single document
document = {
    "@timestamp": "2025-07-18T19:12:34.784Z",
    "container_id": "4bfb0a38ab7545a389f858ff0285e508-2468159923",
    "container_name": "ezid",
    "source": "stderr",
    "log": "127.0.0.1 - - [18/Jul/2025:19:12:34 +0000] \"GET / HTTP/1.1\" 200 5843 0.0006",
    "ecs_cluster": "mrt-ecs-stack",
    "ecs_task_arn": "arn:aws:ecs:us-west-2:671846987296:task/mrt-ecs-stack/4bfb0a38ab7545a389f858ff0285e508",
    "ecs_task_definition": "uc3-mrt-ecs-docker-service-mock-ezid-TaskDefinitionezid-23LbKViVl1MD:1"
}
print('\nIndexing single document:')
index_response = client.index(
    index = index_name,
    body = document,
)
print(index_response)


# perform a bulk index
bulk_data = [
    {"_index": index_name, "_source": document},
    {"_index": index_name, "_source": document},
    {"_index": index_name, "_source": document},
    {"_index": index_name, "_source": document},
]
print('\nBulk index:')
bulk_response = bulk(client, bulk_data)
print(bulk_response)


# # delete the index
# delete_response = client.indices.delete(
#     index_name
# )
# print('\nDeleting index:')
# print(delete_response)
