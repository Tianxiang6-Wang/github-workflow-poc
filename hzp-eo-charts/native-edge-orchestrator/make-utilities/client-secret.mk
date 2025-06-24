## Copyright © 2022 Dell Inc. or its subsidiaries. All Rights Reserved.
## Adding client cert creation here as Key Storage is not ready yet, should be removed once Key Storage is ready
include make-utilities/check-env.mk

CA_CERT     := mtls_ca.crt
CA_KEY      := mtls_ca.key
CLIENT_KEY  := client.key
CLIENT_CSR  := client.csr
CLIENT_CERT := client.crt

CA_RECOVERY_CERT := recovery_ca.crt
CA_RECOVERY_KEY  := recovery_ca.key
RECOVERY_KEY     := recovery.key
RECOVERY_CSR     := recovery.csr
RECOVERY_CERT    := recovery.crt

MTLS_HOST := mtls.edge.internal.use.only
MTLS_RECOVERY_HOST := mtls.recovery.edge.internal.use.only

VAULT_URL        := http://edgevault.$(NAMESPACE).svc.cluster.local:8200
VAULT_ROOT_TOKEN := $(shell $(KUBE_CTL) get secret vault-secret -n $(NAMESPACE) --template={{.data.ROOT_TOKEN}} | base64 --decode)
CLIENT_CSR_DATA  := $(shell cat $(CLIENT_CSR) | jq --raw-input --slurp --compact-output .)
RECOVERY_CSR_DATA  := $(shell cat $(RECOVERY_CSR) | jq --raw-input --slurp --compact-output .)

## Create client CSR
create-client-csr:
	@openssl ecparam -out $(CLIENT_KEY) -name secp384r1 -genkey 2>/dev/null
	@export MSYS_NO_PATHCONV=1 && openssl req -new -key $(CLIENT_KEY) -out $(CLIENT_CSR) -sha384 -nodes -subj "/CN=$(MTLS_HOST)/O=Dell organization" -addext \
	"subjectAltName=DNS:$(MTLS_HOST)" 2>/dev/null

## Sign client CSR with Vault eo pki role
sign-client-csr: start-curl-pod
	$(KUBE_CTL) exec nginx-client-csr -n $(NAMESPACE) -- curl -H "X-Vault-Token: $(VAULT_ROOT_TOKEN)" -X POST --data '{"csr": $(CLIENT_CSR_DATA), "common_name": "$(MTLS_HOST)", "alt_names": "$(MTLS_HOST)"}' $(VAULT_URL)/v1/pki/eo/sign/ece-pki-role \
	| head -n 1 > tmpcrtfile && \
	cat tmpcrtfile | jq -r .data.certificate > $(CLIENT_CERT) && \
	cat tmpcrtfile | jq -r .data.issuing_ca > $(CA_CERT) && \
	rm tmpcrtfile 2>/dev/null
	$(KUBE_CTL) delete po nginx-client-csr -n $(NAMESPACE) --force 2>/dev/null || echo "nginx pod already deleted.";

## Create recovery CSR
create-recovery-csr:
	@openssl ecparam -out $(RECOVERY_KEY) -name secp384r1 -genkey 2>/dev/null
	@export MSYS_NO_PATHCONV=1 && openssl req -new -key $(RECOVERY_KEY) -out $(RECOVERY_CSR) -sha384 -nodes -subj "/CN=$(MTLS_RECOVERY_HOST)/O=Dell organization" -addext \
	"subjectAltName=DNS:$(MTLS_RECOVERY_HOST)" 2>/dev/null

## Sign recovery CSR with Vault recovery pki role
sign-recovery-csr: start-curl-pod
	$(KUBE_CTL) exec nginx-client-csr -n $(NAMESPACE) -- curl -H "X-Vault-Token: $(VAULT_ROOT_TOKEN)" -X POST --data '{"csr": $(RECOVERY_CSR_DATA), "common_name": "$(MTLS_RECOVERY_HOST)", "alt_names": "$(MTLS_RECOVERY_HOST)"}' $(VAULT_URL)/v1/pki/eo/sign/recovery-pki-role-384 \
	| head -n 1 > tmpcrtfile && \
	cat tmpcrtfile | jq -r .data.certificate > $(RECOVERY_CERT) && \
	cat tmpcrtfile | jq -r .data.issuing_ca > $(CA_RECOVERY_CERT) && \
	rm tmpcrtfile 2>/dev/null
	$(KUBE_CTL) delete po nginx-client-csr -n $(NAMESPACE) --force 2>/dev/null || echo "nginx pod already deleted.";

start-curl-pod: stop-curl-pod
	$(KUBE_CTL) run -n $(NAMESPACE) nginx-client-csr --image=$(IMAGE_REGISTRY)/nginx --restart=Never --labels="hzp-role=init-check,hzp.iam.webhook/active=false,sidecar.istio.io/inject=false" || echo "nginx-client-csr pod exists already."
	$(KUBE_CTL) wait -n $(NAMESPACE) --for=condition=Ready pod/nginx-client-csr >/dev/null
	@sleep 15

stop-curl-pod:
	$(KUBE_CTL) delete po nginx-client-csr -n $(NAMESPACE) --force 2>/dev/null || echo "nginx pod already deleted."
