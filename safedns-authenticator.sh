#!/bin/bash

# Get your API key from https://developers.ukfast.io/getting-started
API_KEY=$(</root/.ukfast-api-token)
if [ -z "$API_KEY" ]; then
  echo "Missing UKFast API key"
  exit 1
fi


# Check context of script init, $CERTBOT_AUTH_OUTPUT is only passed to the cleanup script
[ -z "$CERTBOT_AUTH_OUTPUT" ] && ACTION="AUTH" || ACTION="CLEANUP"

# check /temp for zone id 
if [ -f /tmp/CERTBOT_$CERTBOT_DOMAIN/ZONE_ID ]; then
    ZONE_ID=$(cat /tmp/CERTBOT_$CERTBOT_DOMAIN/ZONE_ID)
fi

# poll api for possible zones
if [ -z "$ZONE_ID" ]; then
    STRIP_COUNT=1
    while true; do
        POSSIBLE_ZONE=$(echo "$CERTBOT_DOMAIN" | cut -d . -f ${STRIP_COUNT}-)

        if [ -z "$POSSIBLE_ZONE" ]; then
            echo "No zone for domain \"$CERTBOT_DOMAIN\" found." 1>&2
            exit 1
        fi

        STATUS=$(curl -s -o /dev/null -w '%{http_code}' \
        "https://api.ukfast.io/safedns/v1/zones/$POSSIBLE_ZONE" \
        -H "Authorization: $API_KEY")
        
        if [ $STATUS -eq 200 ]; then
            ZONE_ID=$POSSIBLE_ZONE
            break;
        fi
        
        STRIP_COUNT=$(expr $STRIP_COUNT + 1)
    done
fi


# create auth record
if [ "$ACTION" = "AUTH" ]; then
    RECORD_NAME="_acme-challenge.$CERTBOT_DOMAIN"
    RECORD_CONTENT="$CERTBOT_VALIDATION"

    RECORD_ID=$(curl -s -X POST "https://api.ukfast.io/safedns/v1/zones/$ZONE_ID/records" \
    -H     "Authorization: $API_KEY" \
    -H     "Content-Type: application/json" \
    --data '{"type":"TXT","name":"'$RECORD_NAME'","content":"\"'$RECORD_CONTENT'\"","ttl":120}' \
    | python -c "import sys,json;print(json.load(sys.stdin)['data']['id'])")


    # temp save info for cleanup script
    if [ ! -d /tmp/CERTBOT_$CERTBOT_DOMAIN ];then
            mkdir -m 0700 /tmp/CERTBOT_$CERTBOT_DOMAIN
    fi
    
    echo $ZONE_ID > /tmp/CERTBOT_$CERTBOT_DOMAIN/ZONE_ID
    echo $RECORD_ID > /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID

    # short sleep to give time to propagate
    sleep 5
fi


# cleanup auth record
if [ "$ACTION" = "CLEANUP" ]; then
    if [ -f /tmp/CERTBOT_$CERTBOT_DOMAIN/ZONE_ID ]; then
            rm -f /tmp/CERTBOT_$CERTBOT_DOMAIN/ZONE_ID
    fi

    if [ -f /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID ]; then
            RECORD_ID=$(cat /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID)
            rm -f /tmp/CERTBOT_$CERTBOT_DOMAIN/RECORD_ID
    fi

    # Remove the challenge TXT record from the zone
    if [ -n "${ZONE_ID}" ]; then
        if [ -n "${RECORD_ID}" ]; then
            curl -s -X DELETE "https://api.ukfast.io/safedns/v1/zones/$ZONE_ID/records/$RECORD_ID" \
                    -H "Authorization: $API_KEY" \
                    -H "Content-Type: application/json"    
                    
            DELETE_OK=$?
            if [ $DELETE_OK -ne 0 ]; then
                echo "Could not clean up auth record, please delete manually" 1>&2
            fi                
        fi
    fi
fi
