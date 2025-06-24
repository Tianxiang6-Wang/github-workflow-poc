## Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

ENV_FILE                 := ./.env
READ_ENV_FILE           := `cat $(ENV_FILE)`
KUBE_CTL := $(shell . $(ENV_FILE);if [[ -z $$CLUSTER_NAME ]]; then echo "kubectl"; else echo "kubectl --context=$$CLUSTER_NAME"; fi;)

## Check the existence of .env file and the content
check-env:
ifeq ("$(wildcard $(ENV_FILE))","")
	$(error .env file does not exist, please refer to README on how to create .env in your parent directory!)
endif
	@if [[ -z $(READ_ENV_FILE) ]]; then \
		echo "The .env file is empty, please make sure you have set the environment variables in .env file properly"; \
	else \
		DOCKER_CONFIG_FLAG="false"; \
		PASSWORD_FLAG="false"; \
		FQDN_FLAG="false"; \
		for file in $(READ_ENV_FILE); do \
			if [[ $${file} =~ "DOCKER_CONFIG_JSON" ]]; then \
				DOCKER_CONFIG_FLAG="true"; \
				if [[ $${file} =~ "DOCKER_CONFIG_JSON"=$$ ]] || [[ $${file} =~ ^DOCKER_CONFIG_JSON=[^A-Za-z0-9]+ ]]; then \
					echo "Please check if you have set your "DOCKER_CONFIG_JSON" properly"; \
				fi; \
			elif [[ $${file} =~ "PASSWORD" ]]; then \
				PASSWORD_FLAG="true"; \
			elif [[ $${file} =~ "FQDN" ]]; then \
				FQDN_FLAG="true"; \
				if [[ $${file} =~ "FQDN"=$$ ]] || [[ $${file} =~ ^FQDN=[^A-Za-z0-9.-]+ ]]; then \
					echo "Please check if you have set your "FQDN" properly"; \
				fi; \
			fi; \
		done ; \
		if [[ $$DOCKER_CONFIG_FLAG == "false" || $$FQDN_FLAG == "false" ]]; then \
			echo "------------------------------------------------------------------------------------"; \
			echo "|                                                                                  |"; \
			echo "|                DOCKER_CONFIG_JSON or FQDN is not set, please set it!             |"; \
			echo "|                                                                                  |"; \
			echo "------------------------------------------------------------------------------------"; \
		elif [[ $$PASSWORD_FLAG == "false" ]]; then \
			echo "Passwords will be auto-generated with random strings, please refer to README on how to obtain the passwords"; \
		fi; \
	fi;

