#!/bin/sh

FINALIZE=$(echo $1 | tr '[:upper:]' '[:lower:]')
INSTALL_MINION=$(echo $2 | tr '[:upper:]' '[:lower:]')
MASTER_IP=$3
USERNAME=$4
PASSWORD=$5
MINION_ID=$6
MINION_VERSION=$7

install_minion()
{
	sudo /bin/bash bootstrap-salt.sh -A $MASTER_IP -i $MINION_ID git "v${MINION_VERSION}"
}

autosign_minion()
{

	TOKEN=$(curl  --insecure --request POST \
	  --url "https://${MASTER_IP}/login" \
	  --header 'content-type: application/json' \
	  --data "{\"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\", \"eauth\": \"pam\"}" | \
	    python2 -c "import sys, json; print json.load(sys.stdin)['return'][0]['token']")

	curl --insecure --request POST \
	  --url "https://${MASTER_IP}/" \
	  --header 'content-type: application/json' \
	  --header "x-auth-token: ${TOKEN}" \
	  --data "{\"client\": \"local\", \"tgt\": \"saltmaster\", \"fun\": \"cmd.run\", \"arg\":\"touch /etc/salt/pki/master/minions_autosign/${MINION_ID}\"}"
}

if [ "$FINALIZE" = "true" ]
then
	sh ./Ubuntu_PP.sh >>/tmp/fjcmp_pp.log 2>&1 &
fi

if [ "$INSTALL_MINION" = "true" ]
then
	install_minion
	sleep 10
	autosign_minion
fi
