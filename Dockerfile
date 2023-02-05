FROM hyperledger/fabric-peer:2.4 AS packager

RUN mkdir /tmp/cc-build-env

WORKDIR /tmp/cc-build-env

COPY . .

RUN apk add jq

RUN VERSION=$(cat package.json | jq -r '.version') \
    && CHAINCODE=$(cat package.json | jq -r '.name') \
    && peer lifecycle chaincode package $CHAINCODE@$VERSION.tar.gz --path . --lang node --label $CHAINCODE_$VERSION \
    && echo $CHAINCODE >> chaincodeName.txt \
    && echo $VERSION >> chaincodeVersion.txt

FROM ibmcom/ibp-ansible as ansible-deployer


RUN mkdir /tmp/ibp-deployment

WORKDIR /tmp/ibp-deployment

COPY ./ibp-deployment ./
COPY --from=packager --chown=ibp-user /tmp/cc-build-env/*.tar.gz .
COPY --from=packager --chown=ibp-user /tmp/cc-build-env/*.txt .

USER root
RUN chmod 0644 *.tar.gz
RUN chmod 0777 install_chaincode.sh

RUN chown ibp-user:ibp-user *
RUN ls -all

USER ibp-user

ENTRYPOINT [ "./install_chaincode.sh", "install" ]
