#!/bin/bash

#clone hlf-operator repository
git clone https://github.com/hyperledger-labs/hlf-operator.git

#create a kind kubernetes cluster
# kind create cluster --config=./kind-cluster/config.yaml --wait 30s
kind create cluster --image=kindest/node:v1.22.2

#create a minikube kubernetes cluster
# minikube start
#Installing istio
kubectl apply -f ./hlf-operator/hack/istio-operator/crds/*
helm template ./hlf-operator/hack/istio-operator/ --set hub=docker.io/istio --set tag=1.8.0 --set operatorNamespace=istio-operator --set watchedNamespaces=istio-system | kubectl apply -f -
kubectl create ns istio-system
kubectl apply -n istio-system -f ./hlf-operator/hack/istio-operator.yaml

#Installing the HLF operator
helm repo add kfs https://kfsoftware.github.io/hlf-helm-charts --force-update
helm install hlf-operator --version=1.6.0 kfs/hlf-operator

#Installing the Kubectl HLF Plugin
kubectl krew install hlf
kubectl krew upgrade hlf

# lens