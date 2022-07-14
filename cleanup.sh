#!/bin/bash

#minikube delete
kind delete cluster

rm admin-ordservice.yaml admin-tls-ordservice.yaml connection.json metadata.json mychannel.block networkConfig.yaml ordservice.yaml org1-peer.yaml org2-peer.yaml
rm -rf hlf-operator msp code.tar.gz mycc-external.tgz keystore