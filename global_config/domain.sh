CONFIG=production
CONFIG_SHORT=pd
AZURE_SUBSCRIPTION=s189-teacher-services-cloud-production
RESOURCE_NAME_PREFIX=s189p01
ENV_TAG=Prod
DNS_ZONE=afqts
RESOURCE_GROUP_NAME=${RESOURCE_NAME_PREFIX}-${DNS_ZONE}domains-rg
KEYVAULT_NAME=${RESOURCE_NAME_PREFIX}-${DNS_ZONE}domains-kv
STORAGE_ACCOUNT_NAME=${RESOURCE_NAME_PREFIX}${DNS_ZONE}domainstf
DOMAINS_ID=afqts
