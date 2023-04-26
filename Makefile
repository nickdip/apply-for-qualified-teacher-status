.DEFAULT_GOAL		:=help
SHELL				:=/bin/bash

SERVICE_SHORT=afqts

.PHONY: help # default target
help: ## Show this help
	@grep -E '^[a-zA-Z\.\-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: paas
paas:
	$(eval PLATFORM=paas)
	$(eval REGION=West Europe)

.PHONY: aks
aks:
	$(eval PLATFORM=aks)
	$(eval REGION=UK South)
	$(eval STORAGE_ACCOUNT_SUFFIX=sa)

.PHONY: dev
dev: paas
	$(eval DEPLOY_ENV=dev)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-development)
	$(eval AZURE_RESOURCE_PREFIX=s165d01)
	$(eval CONFIG_SHORT=dv)
	$(eval ENV_TAG=dev)

.PHONY: test
test: paas
	$(eval DEPLOY_ENV=test)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-test)
	$(eval AZURE_RESOURCE_PREFIX=s165t01)
	$(eval CONFIG_SHORT=ts)
	$(eval ENV_TAG=test)

.PHONY: preprod
preprod: paas
	$(eval DEPLOY_ENV=preprod)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-test)
	$(eval AZURE_RESOURCE_PREFIX=s165t01)
	$(eval CONFIG_SHORT=pp)
	$(eval ENV_TAG=pre-prod)

.PHONY: production
production: paas
	$(if $(CONFIRM_PRODUCTION), , $(error Can only run with CONFIRM_PRODUCTION))
	$(eval DEPLOY_ENV=production)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-production)
	$(eval AZURE_RESOURCE_PREFIX=s165p01)
	$(eval CONFIG_SHORT=pd)
	$(eval ENV_TAG=prod)
	$(eval AZURE_BACKUP_STORAGE_ACCOUNT_NAME=s165p01afqtsdbbackuppd)
	$(eval AZURE_BACKUP_STORAGE_CONTAINER_NAME=apply-for-qts)

.PHONY: review
review: paas
	$(if $(pr_id), , $(error Missing environment variable "pr_id"))
	$(eval DEPLOY_ENV=review)
	$(eval AZURE_SUBSCRIPTION=s165-teachingqualificationsservice-development)
	$(eval AZURE_RESOURCE_PREFIX=s165d01)
	$(eval CONFIG_SHORT=rv)
	$(eval ENV_TAG=rev)
	$(eval env=-pr-$(pr_id))
	$(eval backend_config=-backend-config="key=review/review$(env).tfstate")
	$(eval export TF_VAR_app_suffix=$(env))
	$(eval export TF_VAR_forms_storage_account_name=$(AZURE_RESOURCE_PREFIX)afqtsformspr$(pr_id))

.PHONY: review_aks
review_aks: aks
	$(if $(pr_id), , $(error Missing environment variable "pr_id"))
	$(eval include global_config/review_aks.sh)
	$(eval env=-pr-$(pr_id))
	$(eval backend_config=-backend-config="key=review/review$(env).tfstate")
	$(eval export TF_VAR_app_suffix=$(env))
	$(eval export TF_VAR_forms_storage_account_name=$(AZURE_RESOURCE_PREFIX)afqtsformspr$(pr_id))

.PHONY: dev_aks
dev_aks: aks
	$(eval include global_config/dev_aks.sh)

read-keyvault-config:
	$(if $(PLATFORM), , $(error Missing environment variable "PLATFORM"))
	$(eval KEY_VAULT_NAME=$(shell jq -r '.key_vault_name' terraform/$(PLATFORM)/workspace_variables/$(DEPLOY_ENV).tfvars.json))
	$(eval KEY_VAULT_SECRET_NAME=APPLY-QTS-APP-VARIABLES)

read-deployment-config:
	$(if $(PLATFORM), , $(error Missing environment variable "PLATFORM"))
	$(eval SPACE=$(shell jq -r '.paas_space' terraform/$(PLATFORM)/workspace_variables/$(DEPLOY_ENV).tfvars.json))
	$(eval POSTGRES_DATABASE_NAME="apply-for-qts-in-england-$(DEPLOY_ENV)-pg-svc")
	$(eval API_APP_NAME="apply-for-qts-in-england-$(DEPLOY_ENV)")

set-azure-account: ${environment}
	echo "Logging on to ${AZURE_SUBSCRIPTION}"
	az account set -s ${AZURE_SUBSCRIPTION}

ci:	## Run in automation environment
	$(eval DISABLE_PASSCODE=true)
	$(eval AUTO_APPROVE=-auto-approve)
	$(eval SP_AUTH=true)
	$(eval CONFIRM_PRODUCTION=true)

.PHONY: install-fetch-config
install-fetch-config: ## Install the fetch-config script, for viewing/editing secrets in Azure Key Vault
	[ ! -f bin/fetch_config.rb ] \
		&& curl -s https://raw.githubusercontent.com/DFE-Digital/bat-platform-building-blocks/master/scripts/fetch_config/fetch_config.rb -o bin/fetch_config.rb \
		&& chmod +x bin/fetch_config.rb \
		|| true

edit-keyvault-secret: read-keyvault-config install-fetch-config set-azure-account
	bin/fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT_NAME}/${KEY_VAULT_SECRET_NAME} \
		-e -d azure-key-vault-secret:${KEY_VAULT_NAME}/${KEY_VAULT_SECRET_NAME} -f yaml -c

print-keyvault-secret: read-keyvault-config install-fetch-config set-azure-account
	bin/fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT_NAME}/${KEY_VAULT_SECRET_NAME} -f yaml

validate-keyvault-secret: read-keyvault-config install-fetch-config set-azure-account
	bin/fetch_config.rb -s azure-key-vault-secret:${KEY_VAULT_NAME}/${KEY_VAULT_SECRET_NAME} -d quiet \
		&& echo Data in ${KEY_VAULT_NAME}/${KEY_VAULT_SECRET_NAME} looks valid

.PHONY: set-space-developer
set-space-developer: read-deployment-config ## make production set-space-developer USER_ID=first.last@digital.education.gov.uk
	$(if $(USER_ID), , $(error Missing environment variable "USER_ID", USER_ID required for this command to run))
	cf set-space-role ${USER_ID} dfe ${SPACE} SpaceDeveloper

.PHONY: unset-space-developer
unset-space-developer: read-deployment-config ## make production unset-space-developer USER_ID=first.last@digital.education.gov.uk
	$(if $(USER_ID), , $(error Missing environment variable "USER_ID", USER_ID required for this command to run))
	cf unset-space-role ${USER_ID} dfe ${SPACE} SpaceDeveloper

stop-app: read-deployment-config ## Stops api app, make production stop-app CONFIRM_STOP=1
	$(if $(CONFIRM_STOP), , $(error stop-app can only run with CONFIRM_STOP))
	cf target -s ${SPACE}
	cf stop ${API_APP_NAME}

get-postgres-instance-guid: read-deployment-config ## Gets the postgres service instance's guid
	cf target -s ${SPACE} > /dev/null
	cf service ${POSTGRES_DATABASE_NAME} --guid
	$(eval DB_INSTANCE_GUID=$(shell cf service ${POSTGRES_DATABASE_NAME} --guid))

rename-postgres-service: read-deployment-config ## make production rename-postgres-service NEW_NAME_SUFFIX=old CONFIRM_RENAME
	$(if $(CONFIRM_RENAME), , $(error can only run with CONFIRM_RENAME))
	$(if $(NEW_NAME_SUFFIX), , $(error NEW_NAME_SUFFIX is required))
	cf target -s ${SPACE} > /dev/null
	cf rename-service  ${POSTGRES_DATABASE_NAME} ${POSTGRES_DATABASE_NAME}-$(NEW_NAME_SUFFIX)

remove-postgres-tf-state: terraform-init ## make production remove-postgres-tf-state PASSCODE=XXX
	cd terraform/paas && terraform state rm cloudfoundry_service_instance.postgres

restore-postgres: terraform-init read-deployment-config ## make production restore-postgres DB_INSTANCE_GUID="<cf service db-name --guid>" BEFORE_TIME="yyyy-MM-dd hh:mm:ss" DOCKER_IMAGE=ghcr.io/dfe-digital/apply-for-qualified-teacher-status:<COMMIT_SHA> PASSCODE=<auth code from https://login.london.cloud.service.gov.uk/passcode>
	cf target -s ${SPACE} > /dev/null
	$(if $(DB_INSTANCE_GUID), , $(error can only run with DB_INSTANCE_GUID, get it by running `make production get-postgres-instance-guid`))
	$(if $(BEFORE_TIME), , $(error can only run with BEFORE_TIME, eg BEFORE_TIME="2021-09-14 16:00:00"))
	$(eval export TF_VAR_paas_restore_db_from_db_instance=$(DB_INSTANCE_GUID))
	$(eval export TF_VAR_paas_restore_db_from_point_in_time_before=$(BEFORE_TIME))
	echo "Restoring ${POSTGRES_DATABASE_NAME} from $(TF_VAR_paas_restore_db_from_db_instance) before $(TF_VAR_paas_restore_db_from_point_in_time_before)"
	make ${DEPLOY_ENV} terraform-apply

restore-data-from-backup: read-deployment-config # make production restore-data-from-backup CONFIRM_RESTORE=YES BACKUP_FILENAME="apply-for-qts-in-england-production-pg-svc-2022-07-06-01"
	@if [[ "$(CONFIRM_RESTORE)" != YES ]]; then echo "Please enter "CONFIRM_RESTORE=YES" to run workflow"; exit 1; fi
	$(eval export AZURE_BACKUP_STORAGE_ACCOUNT_NAME=$(AZURE_BACKUP_STORAGE_ACCOUNT_NAME))
	$(if $(BACKUP_FILENAME), , $(error can only run with BACKUP_FILENAME, eg BACKUP_FILENAME="find-a-lost-trn-production-pg-svc-2022-04-28-01"))
	bin/download-db-backup ${AZURE_BACKUP_STORAGE_ACCOUNT_NAME} ${AZURE_BACKUP_STORAGE_CONTAINER_NAME} ${BACKUP_FILENAME}.tar.gz
	bin/restore-db ${DEPLOY_ENV} ${CONFIRM_RESTORE} ${SPACE} ${BACKUP_FILENAME}.sql ${POSTGRES_DATABASE_NAME}

terraform-init:
	$(if $(or $(DISABLE_PASSCODE),$(PASSCODE)), , $(error Missing environment variable "PASSCODE", retrieve from https://login.london.cloud.service.gov.uk/passcode))
	$(if $(DOCKER_IMAGE), , $(error Missing environment variable "DOCKER_IMAGE"))
	$(if $(PLATFORM), , $(error Missing environment variable "PLATFORM"))

	$(eval export TF_VAR_apply_qts_docker_image=$(DOCKER_IMAGE))
	$(eval export TF_VAR_docker_image=$(DOCKER_IMAGE))

	$(eval export TF_VAR_config_short=$(CONFIG_SHORT))
	$(eval export TF_VAR_service_short=$(SERVICE_SHORT))
	$(eval export TF_VAR_azure_resource_prefix=$(AZURE_RESOURCE_PREFIX))

	[[ "${SP_AUTH}" != "true" ]] && az account show && az account set -s $(AZURE_SUBSCRIPTION) || true
	terraform -chdir=terraform/$(PLATFORM) init -backend-config workspace_variables/${DEPLOY_ENV}.backend.tfvars $(backend_config) -upgrade -reconfigure

terraform-plan: terraform-init
	terraform -chdir=terraform/$(PLATFORM) plan -var-file workspace_variables/${DEPLOY_ENV}.tfvars.json

terraform-apply: terraform-init
	terraform -chdir=terraform/$(PLATFORM) apply -var-file workspace_variables/${DEPLOY_ENV}.tfvars.json ${AUTO_APPROVE}

terraform-destroy: terraform-init
	terraform -chdir=terraform/$(PLATFORM) destroy -var-file workspace_variables/${DEPLOY_ENV}.tfvars.json ${AUTO_APPROVE}

set-azure-resource-group-tags: ##Tags that will be added to resource group on its creation in ARM template
	$(eval RG_TAGS=$(shell echo '{"Portfolio": "Early years and Schools Group", "Parent Business":"Teaching Regulation Agency", "Product" : "Apply for QTS in England", "Service Line": "Teaching Workforce", "Service": "Teacher Services", "Service Offering": "Apply for QTS in England", "Environment" : "$(ENV_TAG)"}' | jq . ))

set-azure-template-tag:
	$(eval ARM_TEMPLATE_TAG=1.1.0)

set-what-if:
	$(eval WHAT_IF=--what-if)

check-auto-approve:
	$(if $(AUTO_APPROVE), , $(error can only run with AUTO_APPROVE))

arm-deployment: set-azure-account set-azure-template-tag set-azure-resource-group-tags
	az deployment sub create --name "resourcedeploy-tsc-$(shell date +%Y%m%d%H%M%S)" \
		-l "${REGION}" --template-uri "https://raw.githubusercontent.com/DFE-Digital/tra-shared-services/${ARM_TEMPLATE_TAG}/azure/resourcedeploy.json" \
		--parameters "resourceGroupName=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-rg" 'tags=${RG_TAGS}' \
			"tfStorageAccountName=${AZURE_RESOURCE_PREFIX}${SERVICE_SHORT}tfstate${CONFIG_SHORT}${STORAGE_ACCOUNT_SUFFIX}" "tfStorageContainerName=${SERVICE_SHORT}-tfstate" \
			"keyVaultName=${AZURE_RESOURCE_PREFIX}-${SERVICE_SHORT}-${CONFIG_SHORT}-kv" ${WHAT_IF}

deploy-azure-resources: check-auto-approve arm-deployment # make dev deploy-azure-resources AUTO_APPROVE=1

validate-azure-resources: set-what-if arm-deployment # make dev validate-azure-resources

read-tf-config:
	$(if $(PLATFORM), , $(error Missing environment variable "PLATFORM"))
	$(eval space=$(shell jq -r '.paas_space' terraform/$(PLATFORM)/workspace_variables/$(DEPLOY_ENV).tfvars.json))

enable-maintenance: read-tf-config ## make dev enable-maintenance / make production enable-maintenance CONFIRM_PRODUCTION=y
	cf target -s ${space}
	cd service_unavailable_page && cf push
	cf map-route apply-for-qts-unavailable london.cloudapps.digital --hostname apply-for-qts-in-england-${DEPLOY_ENV}
	echo Waiting 5s for route to be registered... && sleep 5
	cf unmap-route apply-for-qts-in-england-${DEPLOY_ENV} london.cloudapps.digital --hostname apply-for-qts-in-england-${DEPLOY_ENV}

disable-maintenance: read-tf-config ## make dev disable-maintenance / make production disable-maintenance CONFIRM_PRODUCTION=y
	cf target -s ${space}
	cf map-route apply-for-qts-in-england-${DEPLOY_ENV} london.cloudapps.digital --hostname apply-for-qts-in-england-${DEPLOY_ENV}
	echo Waiting 5s for route to be registered... && sleep 5
	cf unmap-route apply-for-qts-unavailable london.cloudapps.digital --hostname apply-for-qts-in-england-${DEPLOY_ENV}
	cf delete apply-for-qts-unavailable -r -f
