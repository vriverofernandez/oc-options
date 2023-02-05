#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
export IBP_ANSIBLE_LOG_FILENAME=/tmp/ibp.log

function usage {
    echo "Usage: build_network.sh [-h] [install]" 1>&2
    exit 1
}

function installChaincode {
    CHANNEL=$1
    CC_NAME=$2
    CC_VERSION=$3
    SEQUENCE=1

    echo " "
    echo "----------"
    echo "Launching install and approve"
    echo "----------"
    echo " "
    set +e
    ansible-playbook 19-install-and-approve-chaincode.yml -e "channel_name=${CHANNEL} smart_contract_name=${CC_NAME} smart_contract_version=${CC_VERSION} smart_contract_sequence=${SEQUENCE}"
    err=$?
    set -e

    if [ $err != 0 ] ; then
        echo " "
        echo "----------"
        echo "Failed - Searching for current SEQUENCE"
        echo "----------"
        echo " "
        cat /tmp/ibp.log | tail
        SEQUENCE="$(grep "new definition must be sequence" /tmp/ibp.log | tail -1 | sed 's/\\n",//' | awk '{print $(NF)}')"

        echo " "
        echo "----------"
        echo "Launching install and approve .SEQUENCE: ${SEQUENCE}"
        echo "----------"
        echo " "

        set +e
        ansible-playbook 19-install-and-approve-chaincode.yml -e "channel_name=${CHANNEL} smart_contract_name=${CC_NAME} smart_contract_version=${CC_VERSION} smart_contract_sequence=${SEQUENCE}"
        errInt=$?
        set -e
        if [ $errInt != 0 ] ; then
          echo " "
          echo "----------"
          echo "Error while executing install and approve"
          echo "----------"
          echo " "
          exit 255
        fi
    fi

    echo " "
    echo "----------"
    echo "Launching commit"
    echo "----------"
    echo " "
    set +e
    ansible-playbook 21-commit-chaincode.yml -e "channel_name=${CHANNEL} smart_contract_name=${CC_NAME} smart_contract_version=${CC_VERSION} smart_contract_sequence=${SEQUENCE}"
    err=$?
    set -e

    if [ $err != 0 ] ; then
      cat /tmp/ibp.log
      echo " "
      echo "----------"
      echo "Error while commiting"
      echo "----------"
      echo " "
      exit 255
    fi
}

while getopts "h" OPT; do
    case ${OPT} in
        h)
            usage
            ;;
        \?)
            usage
            ;;
    esac
done
shift $((OPTIND -1))
COMMAND=$1
if [ "${COMMAND}" = "install" ]; then
    set -x

    # Install and approve items chaincode for every channel
    CC_NAME_F=`cat chaincodeName.txt`
    CC_VERSION_F=`cat chaincodeVersion.txt`
    installChaincode eticket $CC_NAME_F $CC_VERSION_F
    set +x
else
    usage
fi

exit 0
