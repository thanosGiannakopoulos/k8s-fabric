#!/bin/bash

alias k=kubectl

export SC=$(kubectl get sc -o=jsonpath='{.items[0].metadata.name}')

#CREATE A FABRIC NAMESPACE
kubectl create ns fabric

#DEPLOYING THREE CERTIFICATE AUTHORITIES
kubectl hlf ca create --storage-class=$SC --capacity=2Gi --name=org1-ca --enroll-id=enroll --enroll-pw=enrollpw --namespace=fabric
kubectl hlf ca create --storage-class=$SC --capacity=2Gi --name=org2-ca --enroll-id=enroll --enroll-pw=enrollpw --namespace=fabric
kubectl hlf ca create --storage-class=$SC --capacity=2Gi --name=ord-ca --enroll-id=enroll --enroll-pw=enrollpw --namespace=fabric

kubectl wait --timeout=180s --for=condition=Running fabriccas.hlf.kungfusoftware.es -n fabric --all

export PEER_IMAGE=hyperledger/fabric-peer
export PEER_VERSION=2.4.3
export ORDERER_IMAGE=hyperledger/fabric-orderer
export ORDERER_VERSION=2.4.3

#CREATE CRYPTOMATERIAL FOR THE PEERS, IDENTITY AND MSP
kubectl hlf ca register --name=org1-ca --user=org1-peer1 --secret=peerpw --type=peer --enroll-id enroll --enroll-secret=enrollpw --mspid=Org1MSP --namespace=fabric
kubectl hlf ca register --name=org1-ca --user=org1-peer2 --secret=peerpw --type=peer --enroll-id enroll --enroll-secret=enrollpw --mspid=Org1MSP --namespace=fabric
kubectl hlf ca register --name=org2-ca --user=org2-peer1 --secret=peerpw --type=peer --enroll-id enroll --enroll-secret=enrollpw --mspid=Org2MSP --namespace=fabric
kubectl hlf ca register --name=org2-ca --user=org2-peer2 --secret=peerpw --type=peer --enroll-id enroll --enroll-secret=enrollpw --mspid=Org2MSP --namespace=fabric

sleep 10s
#CREATE PEERS FOR org1-peer1, org1-peer2, org2-peer1 and org2-peer2
kubectl hlf peer create --storage-class=$SC --enroll-id=org1-peer1 --mspid=Org1MSP --enroll-pw=peerpw --capacity=5Gi --name=org1-peer1 --ca-name=org1-ca.fabric --namespace=fabric --statedb=couchdb --image=$PEER_IMAGE --version=$PEER_VERSION
kubectl hlf peer create --storage-class=$SC --enroll-id=org1-peer2 --mspid=Org1MSP --enroll-pw=peerpw --capacity=5Gi --name=org1-peer2 --ca-name=org1-ca.fabric --namespace=fabric --statedb=couchdb --image=$PEER_IMAGE --version=$PEER_VERSION
kubectl hlf peer create --storage-class=$SC --enroll-id=org2-peer1 --mspid=Org2MSP --enroll-pw=peerpw --capacity=5Gi --name=org2-peer1 --ca-name=org2-ca.fabric --namespace=fabric --statedb=couchdb --image=$PEER_IMAGE --version=$PEER_VERSION
kubectl hlf peer create --storage-class=$SC --enroll-id=org2-peer2 --mspid=Org2MSP --enroll-pw=peerpw --capacity=5Gi --name=org2-peer2 --ca-name=org2-ca.fabric --namespace=fabric --statedb=couchdb --image=$PEER_IMAGE --version=$PEER_VERSION

kubectl wait --timeout=180s --for=condition=Running fabricpeers.hlf.kungfusoftware.es -n fabric --all

#REGISTER AND ENROLL ADMINS FOR ORG1-CA AND ORG2-CA
kubectl hlf ca register --name=org1-ca --user=admin --secret=adminpw --type=admin --enroll-id enroll --enroll-secret=enrollpw --mspid=Org1MSP --namespace=fabric
kubectl hlf ca enroll --name=org1-ca --user=admin --secret=adminpw --ca-name ca --output org1-peer.yaml --mspid=Org1MSP --namespace=fabric
kubectl hlf ca register --name=org2-ca --user=admin --secret=adminpw --type=admin --enroll-id enroll --enroll-secret=enrollpw --mspid=Org2MSP --namespace=fabric
kubectl hlf ca enroll --name=org2-ca --user=admin --secret=adminpw --ca-name ca --output org2-peer.yaml --mspid=Org2MSP --namespace=fabric

sleep 5s
# REGISTER & CREATE ORDERER
kubectl hlf ca register --name=ord-ca --user=orderer --secret=ordererpw --type=orderer --enroll-id enroll --enroll-secret=enrollpw --mspid=OrdererMSP --namespace=fabric
kubectl hlf ordnode create --storage-class=$SC --enroll-id=orderer --mspid=OrdererMSP --enroll-pw=ordererpw --capacity=2Gi --name=ord-node1 --ca-name=ord-ca.fabric --namespace=fabric --image=$ORDERER_IMAGE --version=$ORDERER_VERSION

kubectl wait --timeout=180s --for=condition=Running fabricorderernodes.hlf.kungfusoftware.es -n fabric --all

#REGISTER  & ENROLL ENTITY FOR ORDERER
kubectl hlf ca register --name=ord-ca --user=admin --secret=adminpw --type=admin --enroll-id enroll --enroll-secret=enrollpw --mspid=OrdererMSP --namespace=fabric
kubectl hlf ca enroll --name=ord-ca --user=admin --secret=adminpw --ca-name ca --output admin-ordservice.yaml --mspid=OrdererMSP --namespace=fabric
kubectl hlf ca enroll --name=ord-ca --user=admin --secret=adminpw --ca-name tlsca --output admin-tls-ordservice.yaml --mspid=OrdererMSP --namespace=fabric

sleep 5s
#CONNECTION PROFILE
kubectl hlf inspect --output ordservice.yaml -o OrdererMSP
sleep 5s
kubectl hlf utils adduser --userPath=admin-ordservice.yaml --config=ordservice.yaml --username=admin --mspid=OrdererMSP
#kubectl hlf utils adduser --userPath=admin-ordservice.yaml --config=networkConfig.yaml --username=admin --mspid=OrdererMSP
sleep 5s
kubectl hlf inspect --output networkConfig.yaml -o Org1MSP -o OrdererMSP -o Org2MSP
sleep 5s
kubectl hlf utils adduser --userPath=org1-peer.yaml --config=networkConfig.yaml --username=admin --mspid=Org1MSP
sleep 5s
kubectl hlf utils adduser --userPath=org2-peer.yaml --config=networkConfig.yaml --username=admin --mspid=Org2MSP

sleep 5s
#CREATE CHANNEL
kubectl hlf channel generate --output=mychannel.block --name=mychannel --organizations Org1MSP --organizations Org2MSP --ordererOrganizations OrdererMSP

sleep 20s
#JOIN ORDERER TO THE CHANNEL, care its the tls certificate 
kubectl hlf ordnode join --block=mychannel.block --name=ord-node1 --namespace=fabric --identity=admin-tls-ordservice.yaml
sleep 5s
#JOIN PEERS TO THE CHANNEL
kubectl hlf channel join --name=mychannel --config=networkConfig.yaml --user=admin -p=org1-peer1.fabric
kubectl hlf channel join --name=mychannel --config=networkConfig.yaml --user=admin -p=org1-peer2.fabric
kubectl hlf channel join --name=mychannel --config=networkConfig.yaml --user=admin -p=org2-peer1.fabric
kubectl hlf channel join --name=mychannel --config=networkConfig.yaml --user=admin -p=org2-peer2.fabric

#MAKE ANCHOR PEERS
kubectl hlf channel addanchorpeer --channel=mychannel --config=networkConfig.yaml --user=admin --peer=org1-peer1.fabric
kubectl hlf channel addanchorpeer --channel=mychannel --config=networkConfig.yaml --user=admin --peer=org2-peer1.fabric