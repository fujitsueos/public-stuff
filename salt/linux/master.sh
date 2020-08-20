#!/bin/sh

INSTALL_MINION=$(echo $1 | tr '[:upper:]' '[:lower:]')
MASTER_IP=$2
USERNAME=$3
PASSWORD=$4
MINION_ID=$5
MINION_VERSION=$6
APPNAMES=$7

TOKEN=$(curl  --insecure --request POST \
  --url "https://${MASTER_IP}/login" \
  --header 'content-type: application/json' \
  --data "{\"username\": \"${USERNAME}\", \"password\": \"${PASSWORD}\", \"eauth\": \"pam\"}" | \
    python2 -c "import sys, json; print json.load(sys.stdin)['return'][0]['token']")


install_minion()
{
	sudo /bin/bash bootstrap-salt.sh -A $MASTER_IP -i $MINION_ID git "v${MINION_VERSION}"
}

autosign_minion()
{


	curl --insecure --request POST \
	  --url "https://${MASTER_IP}/" \
	  --header 'content-type: application/json' \
	  --header "x-auth-token: ${TOKEN}" \
	  --data "{\"client\": \"local\", \"tgt\": \"saltmaster\", \"fun\": \"cmd.run\", \"arg\":\"touch /etc/salt/pki/master/minions_autosign/${MINION_ID}\"}"
}

install_applications()
{
	for i in $(echo $APPNAMES | sed "s/,/ /g")
	do
	    APPNAME=$(echo $i | base64 --decode)

	    JID=$(curl  --insecure --request POST \
		  --url "https://${MASTER_IP}/minions" \
		  --header 'content-type: application/json' \
		  --header "x-auth-token: ${TOKEN}" \
		  --data "{\"client\": \"local\", \"tgt\": \"${MINION_ID}\", \"fun\": \"state.sls\", \"arg\":\"${APPNAME}\"}" | \
		    python2 -c "import sys, json; print json.load(sys.stdin)['return'][0]['jid']")
		sleep 30
	done
}

if [ "$INSTALL_MINION" = "true" ]
then
	install_minion
	sleep 10
	autosign_minion
	sleep 10
	install_applications
fi
