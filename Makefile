MINIKUBE = /usr/bin/env minikube
KUSTOMIZE = /usr/bin/env kustomize
KUBECTL = /usr/bin/env kubectl

ELASTIC-OPERATOR-PATH := vendor/ec-on-k8s
ELASTIC-OPERATOR-FILE := operator.yaml
ELASTIC-OPERATOR-URL := https://download.elastic.co/downloads/eck/2.2.0/operator.yaml

ELASTIC-CUSTOM-RESOURCE-DEFINITIONS--FILE := crds.yaml
ELASTIC-CUSTOM-RESOURCE-DEFINITIONS-URL := https://download.elastic.co/downloads/eck/2.2.0/crds.yaml

$(ELASTIC-OPERATOR-PATH):
	mkdir -p $(ELASTIC-OPERATOR-PATH)

$(ELASTIC-OPERATOR-PATH)/$(ELASTIC-OPERATOR-FILE): $(ELASTIC-OPERATOR-PATH)
	curl -o $(ELASTIC-OPERATOR-PATH)/$(ELASTIC-OPERATOR-FILE) $(ELASTIC-OPERATOR-URL)

$(ELASTIC-OPERATOR-PATH)/$(ELASTIC-CUSTOM-RESOURCE-DEFINITIONS--FILE): $(ELASTIC-OPERATOR-PATH)
	curl -o $(ELASTIC-OPERATOR-PATH)/$(ELASTIC-CUSTOM-RESOURCE-DEFINITIONS--FILE) $(ELASTIC-CUSTOM-RESOURCE-DEFINITIONS-URL)

elastic-operator: $(ELASTIC-OPERATOR-PATH)/$(ELASTIC-OPERATOR-FILE)
	$(KUBECTL) apply -f $(ELASTIC-OPERATOR-PATH)/$(ELASTIC-OPERATOR-FILE)

elastic-custom-resource-definitions: $(ELASTIC-OPERATOR-PATH)/$(ELASTIC-CUSTOM-RESOURCE-DEFINITIONS--FILE)
	$(KUBECTL) apply -f $(ELASTIC-OPERATOR-PATH)/$(ELASTIC-CUSTOM-RESOURCE-DEFINITIONS--FILE)

minikube:
	$(MINIKUBE) start \
	--kubernetes-version=v1.24.3 \
	--vm-driver=docker \
	--cpus=4 \
	--memory=8g \
	--bootstrapper=kubeadm \
	--extra-config=kubelet.authentication-token-webhook=true \
	--extra-config=kubelet.authorization-mode=Webhook \
	--extra-config=scheduler.address=0.0.0.0 \
	--extra-config=controller-manager.address=0.0.0.0
	minikube addons enable ingress
	minikube addons enable default-storageclass
	minikube addons enable storage-provisioner
	minikube addons enable metrics-server

step-1:
	$(KUBECTL) kustomize deploy/step-1 | $(KUBECTL) apply -f -

step-2: elastic-custom-resource-definitions \
	elastic-operator
	$(KUBECTL) kustomize deploy/step-2 | $(KUBECTL) apply -f -

step-3: elastic-custom-resource-definitions \
  elastic-operator
	$(KUBECTL) kustomize deploy/step-3 | $(KUBECTL) apply -f -

step-4: elastic-custom-resource-definitions \
  elastic-operator
	$(KUBECTL) kustomize deploy/step-4 | $(KUBECTL) apply -f -

.PHONY: minikube step-1 step-2 step-3 step-4
