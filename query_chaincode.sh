#!/bin/bash

CC_NAME=$1
PACKAGE_ID=$(kubectl-hlf chaincode calculatepackageid --path=$CC_NAME-external.tgz --language=node --label=$CC_NAME)

kubectl hlf chaincode invoke --config=networkConfig.yaml --user=admin --peer=org1-peer1.fabric --chaincode=$CC_NAME --channel=mychannel --fcn=createCar -a '1000' -a "honda" -a "civic" -a "red" -a "aditya"
# kubectl hlf chaincode query --config=networkConfig.yaml --user=admin --peer=org1-peer1.fabric --chaincode=$CC_NAME --channel=mychannel --fcn=queryAllCars -a ''
# kubectl hlf chaincode query --config=networkConfig.yaml --user=admin --peer=org1-peer1.fabric --chaincode=$CC_NAME --channel=mychannel --fcn=queryCar -a '1000'