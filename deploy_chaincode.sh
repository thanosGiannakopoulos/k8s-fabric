#!/bin/bash

CC_NAME=$1
cat <<METADATA-EOF > "metadata.json"
{
    "type": "ccaas",
    "label": "${CC_NAME}"
}
METADATA-EOF

cat <<CONN_EOF > "connection.json"
{
    "address": "${CC_NAME}:7052",
    "dial_timeout": "10s",
    "tls_required": false
}
CONN_EOF

sleep 5s

tar cfz code.tar.gz connection.json
tar cfz ${CC_NAME}-external.tgz metadata.json code.tar.gz

PACKAGE_ID=$(kubectl-hlf chaincode calculatepackageid --path=$CC_NAME-external.tgz --language=node --label=$CC_NAME)

sleep 5s

kubectl hlf chaincode install --path=./${CC_NAME}-external.tgz --config=networkConfig.yaml --language=node --label=$CC_NAME --user=admin --peer=org1-peer1.fabric
kubectl hlf chaincode install --path=./${CC_NAME}-external.tgz --config=networkConfig.yaml --language=node --label=$CC_NAME --user=admin --peer=org2-peer1.fabric
#DEFINITIIN OF THE CHAINCODE ABOVE
sleep 5s

kubectl hlf externalchaincode sync --image=tgian/fabcar:latest --name=$CC_NAME --namespace=fabric --package-id=$PACKAGE_ID --tls-required=false --replicas=1

export SEQUENCE=1
export VERSION="1.0"
kubectl hlf chaincode approveformyorg --config=networkConfig.yaml --user=admin --peer=org1-peer1.fabric --package-id=$PACKAGE_ID --version $VERSION --sequence $SEQUENCE --name=$CC_NAME --policy="OR('Org1MSP.member','Org2MSP.member')" --channel=mychannel
kubectl hlf chaincode approveformyorg --config=networkConfig.yaml --user=admin --peer=org2-peer1.fabric --package-id=$PACKAGE_ID --version $VERSION --sequence $SEQUENCE --name=$CC_NAME --policy="OR('Org1MSP.member','Org2MSP.member')" --channel=mychannel

kubectl hlf chaincode commit --config=networkConfig.yaml --user=admin --mspid=Org1MSP --version $VERSION --sequence $SEQUENCE --name=$CC_NAME --policy="OR('Org1MSP.member','Org2MSP.member')" --channel=mychannel

#####THIS SHOULD WORK
#kubectl hlf chaincode install --path=./chaincode/fabcar/go --config=networkConfig.yaml --language=goland --label=fabcar --user=admin --peer=org1-peer1.fabric