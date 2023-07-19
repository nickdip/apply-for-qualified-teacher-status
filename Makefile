.DEFAULT_GOAL		:=help
SHELL				:=/bin/bash

SERVICE_SHORT=afqts

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z\._\-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: development_aks
development_aks: ## Specify development AKS environment
	$(eval include global_config/development_aks.sh)

.PHONY: review_aks
review_aks: ## Specify review AKS environment
	$(if $(PULL_REQUEST_NUMBER), , $(error Missing environment variable "PULL_REQUEST_NUMBER"))
	$(eval include global_config/review_aks.sh)
	$(eval backend_config=-backend-config="key=terraform-$(PULL_REQUEST_NUMBER).tfstate")
	$(eval export TF_VAR_app_suffix=-$(PULL_REQUEST_NUMBER))
	$(eval export TF_VAR_uploads_storage_account_name=$(AZURE_RESOURCE_PREFIX)afqtsrv$(PULL_REQUEST_NUMBER)sa)

.PHONY: test_aks
test_aks:  ## Specify test AKS environment
	$(eval include global_config/test_aks.sh)

.PHONY: preproduction_aks
preproduction_aks: ## Specify preproduction AKS environment
	$(eval include global_config/preproduction_aks.sh)

.PHONY: production_aks
production_aks:  ## Specify production AKS environment
	$(eval include global_config/production_aks.sh)

.PHONY: set-key-vault-names
set-key-vault-names:
	$(eval KEY_VAULT_APPLICATION_NAME=$(AZURE_RESOURCE_PREFIX)-$(SERVICE_SHORT)-$(CONFIG_SHORT)-app-kv)
	$(eval KEY_VAULT_INFRASTRUCTURE_NAME=$(AZURE_RESOURCE_PREFIX)-$(SERVICE_SHORT)-$(CONFIG_SHORT)-inf-kv)

.PHONY: print-application-key-vault-name
print-application-key-vault-name: set-key-vault-names  ## Print the name of the application key vault
	echo ${KEY_VAULT_APPLICATION_NAME}

.PHONY: print-infrastructure-key-vault-name
print-infrastructure-key-vault-name: set-key-vault-names  ## Print the name of the infrastructure key vault
	echo ${KEY_VAULT_INFRASTRUCTURE_NAME}

.PHONY: set-resource-group-name
set-resource-group-name:
	$(eval RESOURCE_GROUP_NAME=$(AZURE_RESOURCE_PREFIX)-$(SERVICE_SHORT)-$(CONFIG_SHORT)-rg)

.PHONY: set-storage-account-name
set-storage-account-name:
	$(eval STORAGE_ACCOUNT_NAME=$(AZURE_RESOURCE_PREFIX)$(SERVICE_SHORT)tfstate$(CONFIG_SHORT)sa)

.PHONY: print-resource-group-name
print-resource-group-name: set-resource-group-name
	echo ${RESOURCE_GROUP_NAME}

.PHONY: set-azure-account
set-azure-account:
	echo "Logging on to ${AZURE_SUBSCRIPTION}"
	az account set -s ${AZURE_SUBSCRIPTION}

.PHONY: ci
ci:	## Run in automation environment
	$(eval AUTO_APPROVE=-auto-approve)
	$(eval SP_AUTH=true)
	$(eval CONFIRM_PRODUCTION=true)

bin/konduit.sh:
	curl -s https://raw.githubusercontent.com/DFE-Digital/teacher-services-cloud/main/scripts/konduit.sh -o bin/konduit.sh \
		&& chmod +x bin/konduit.sh

.PHONY: install-konduit
install-konduit: bin/konduit.sh ## Install the konduit script, for accessing backend services

.PHONY: terraform-init
terraform-init:
	$(if $(DOCKER_IMAGE), , $(error Missing environment variable "DOCKER_IMAGE"))

	$(eval export TF_VAR_docker_image=$(DOCKER_IMAGE))
	$(eval export TF_VAR_config_short=$(CONFIG_SHORT))
	$(eval export TF_VAR_service_short=$(SERVICE_SHORT))
	$(eval export TF_VAR_azure_resource_prefix=$(AZURE_RESOURCE_PREFIX))

	[[ "${SP_AUTH}" != "true" ]] && az account show && az account set -s $(AZURE_SUBSCRIPTION) || true
	terraform -chdir=terraform/application init -backend-config workspace_variables/$(CONFIG).backend.tfvars $(backend_config) -upgrade -reconfigure

.PHONY: terraform-plan
terraform-plan: terraform-init
	terraform -chdir=terraform/application plan -var-file workspace_variables/$(CONFIG).tfvars.json

.PHONY: terraform-refresh
terraform-refresh: terraform-init
	terraform -chdir=terraform/application refresh -var-file workspace_variables/$(CONFIG).tfvars.json

.PHONY: terraform-apply
terraform-apply: terraform-init
	terraform -chdir=terraform/application apply -var-file workspace_variables/$(CONFIG).tfvars.json ${AUTO_APPROVE}

.PHONY: terraform-destroy
terraform-destroy: terraform-init
	terraform -chdir=terraform/application destroy -var-file workspace_variables/$(CONFIG).tfvars.json ${AUTO_APPROVE}

.PHONY: set-azure-resource-group-tags
set-azure-resource-group-tags: ##Tags that will be added to resource group on its creation in ARM template
	$(eval RG_TAGS=$(shell echo '{"Portfolio": "Early years and Schools Group", "Parent Business":"Teaching Regulation Agency", "Product" : "Apply for QTS in England", "Service Line": "Teaching Workforce", "Service": "Teacher Services", "Service Offering": "Apply for QTS in England", "Environment" : "$(ENV_TAG)"}' | jq . ))

.PHONY: set-azure-template-tag
set-azure-template-tag:
	$(eval ARM_TEMPLATE_TAG=1.1.6)

.PHONY: set-what-if
set-what-if:
	$(eval WHAT_IF=--what-if)

.PHONY: check-auto-approve
check-auto-approve:
	$(if $(AUTO_APPROVE), , $(error can only run with AUTO_APPROVE))

.PHONY: arm-deployment
arm-deployment: set-resource-group-name set-storage-account-name set-azure-account set-azure-template-tag set-azure-resource-group-tags set-key-vault-names
	az deployment sub create --name "resourcedeploy-tsc-$(shell date +%Y%m%d%H%M%S)" \
		-l "UK South" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${RESOURCE_GROUP_NAME}" 'tags=${RG_TAGS}' \
			"tfStorageAccountName=${STORAGE_ACCOUNT_NAME}" "tfStorageContainerName=${SERVICE_SHORT}-tfstate" \
			keyVaultNames='("${KEY_VAULT_APPLICATION_NAME}", "${KEY_VAULT_INFRASTRUCTURE_NAME}")' \
			"enableKVPurgeProtection=false" ${WHAT_IF}

.PHONY: deploy-azure-resources
deploy-azure-resources: check-auto-approve arm-deployment # make development_aks deploy-azure-resources AUTO_APPROVE=1

.PHONY: validate-azure-resources
validate-azure-resources: set-what-if arm-deployment # make development_aks validate-azure-resources

validate-domain-resources: set-what-if domain-azure-resources # make publish validate-domain-resources AUTO_APPROVE=1

deploy-domain-resources: check-auto-approve domain-azure-resources # make publish deploy-domain-resources AUTO_APPROVE=1

.PHONY: afqts_domain
afqts_domain:   ## runs a script to config variables for setting up dns
	$(eval include global_config/domain.sh)

domains-infra-init: afqts_domain set-azure-account ## make domains-infra-init -  terraform init for dns core resources, eg Main FrontDoor resource
	terraform -chdir=terraform/domains/infrastructure init -reconfigure -upgrade \
		-backend-config=workspace_variables/${DOMAINS_ID}_backend.tfvars

domains-infra-plan: domains-infra-init ## terraform plan for dns core resources
	terraform -chdir=terraform/domains/infrastructure plan -var-file workspace_variables/${DOMAINS_ID}.tfvars.json

domains-infra-apply: domains-infra-init ## terraform apply for dns core resources
	terraform -chdir=terraform/domains/infrastructure apply -var-file workspace_variables/${DOMAINS_ID}.tfvars.json ${AUTO_APPROVE}

domains-init: afqts_domain set-azure-account ## terraform init for dns resources: make <env>  domains-init
	terraform -chdir=terraform/domains/environment_domains init -upgrade -reconfigure -backend-config=workspace_variables/$(CONFIG)_backend.tfvars

domains-plan: domains-init  ## terraform plan for dns resources, eg dev.<domain_name> dns records and frontdoor routing
	terraform -chdir=terraform/domains/environment_domains plan -var-file workspace_variables/$(CONFIG).tfvars.json

domains-apply: domains-init ## terraform apply for dns resources
	terraform -chdir=terraform/domains/environment_domains apply -var-file workspace_variables/$(CONFIG).tfvars.json ${AUTO_APPROVE}

domains-destroy: domains-init ## terraform destroy for dns resources
	terraform -chdir=terraform/domains/environment_domains destroy -var-file workspace_variables/$(CONFIG).tfvars.json

domains-development:
	$(eval CONFIG=dev)

domains-test:
	$(eval CONFIG=test)

domains-preprod:
	$(eval CONFIG=preprod)

domains-production:
	$(eval CONFIG=production)

domain-azure-resources: set-azure-account set-azure-template-tag set-azure-resource-group-tags ## deploy container to store terraform state for all dns resources -run validate first
	$(if $(AUTO_APPROVE), , $(error can only run with AUTO_APPROVE))
	az deployment sub create -l "UK South" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--name "${DNS_ZONE}domains-$(shell date +%Y%m%d%H%M%S)" --parameters "resourceGroupName=${RESOURCE_NAME_PREFIX}-${DNS_ZONE}domains-rg" 'tags=${RG_TAGS}' \
			"tfStorageAccountName=${RESOURCE_NAME_PREFIX}${DNS_ZONE}domainstf" "tfStorageContainerName=${DNS_ZONE}domains-tf"  "keyVaultName=${RESOURCE_NAME_PREFIX}-${DNS_ZONE}domains-kv" ${WHAT_IF}

validate-domain-resources: set-what-if domain-azure-resources ## make  validate-domain-resources  - validate resource against Azure
