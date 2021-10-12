#!/bin/sh

INSTALL_MINION=$(echo $1 | tr '[:upper:]' '[:lower:]')
MASTER_HOSTNAME=$2
MASTER_URL=$3
USERNAME=$4
PASSWORD=$5
MINION_ID=$6
MINION_VERSION=$7


install_minion()
{
	sudo /bin/bash bootstrap-salt.sh -A $MASTER_HOSTNAME -i $MINION_ID git "v${MINION_VERSION}"
}

autosign_minion()
{
	TOKEN=$(curl --retry 10 --insecure --request POST \
	  --url "${MASTER_URL}/login" \
	  --header 'content-type: application/json' \
	  --data "{\"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\", \"eauth\": \"pam\"}" | \
	    python2 -c "import sys, json; print json.load(sys.stdin)['return'][0]['token']")

	curl --retry 10 --insecure --request POST \
	  --url "${MASTER_URL}/" \
	  --header 'content-type: application/json' \
	  --header "x-auth-token: ${TOKEN}" \
	  --data "{\"client\": \"local\", \"tgt\": \"saltmaster\", \"fun\": \"cmd.run\", \"arg\":\"touch /etc/salt/pki/master/minions_autosign/${MINION_ID}\"}"
}

if [ "$INSTALL_MINION" = "true" ]
then
        sleep 10
	install_minion
	sleep 10
	autosign_minion
fi
