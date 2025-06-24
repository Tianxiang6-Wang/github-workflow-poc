## Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.

## Clean up all persistent volume claim
delete-pvc:
	kubectl get pvc -n $(NAMESPACE) --no-headers=true | awk '/$(VAULT_PVC_PREFIX)|$(POSTGRES_PVC)|$(NATS_PVC)|$(ARCHIVE_PVC)/{print $$1}' | xargs  kubectl delete -n $(NAMESPACE) pvc
