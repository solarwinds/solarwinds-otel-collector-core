#!/usr/bin/bash

REPORT_FILE="$1"
TITLE="$2"

REPORT=$(cat "$REPORT_FILE")

# Slack message character limit is 3000, so we need to split the message into chunks
# You can reply to slack message by specifying its timestamp, which is returned in the response.
send_to_slack_thread_in_chunks() {
  local full_message="$1"
  local timestamp="$2"
  local chunk_size=2990
  local start=0

  while [ $start -lt ${#full_message} ]; do
    # Extract a chunk of the message
    local chunk="${full_message:$start:$chunk_size}"
    
    # Low effort Slack throttling avoidance
    sleep 1 
    echo "Sending chunk to Slack"
    chunk=$(jq -Rsa '.' <<< "$chunk")
    # Send the chunk via curl
    curl -X POST \
      --data "{\"channel\":\"$SLACK_CHANNEL\",\"thread_ts\":\"$timestamp\",\"text\":$chunk}" \
      -H "Authorization: Bearer $SLACK_REPORTER_TOKEN" \
      -H "Content-Type: application/json" \
      https://slack.com/api/chat.postMessage

    # Check if curl was successful
    if [ $? -ne 0 ]; then
      echo "Error sending chunk to Slack" >&2
      return 1
    fi

    # Move to the next chunk
    start=$((start + chunk_size))
  done
}

if [ -z "$REPORT_FILE" ]; then
  echo "Error: Missing REPORT_FILE parameter!"
  exit 1
fi

# Check if the report file сontains vulnerabilities keyword
if grep -q -i "vulnerability" "$REPORT_FILE"; then
  ICON=":red_circle:"
  MESSAGE="Vulnerability check failed!"
else
  ICON=":green_circle:"
  MESSAGE="No vulnerabilities found."
fi

# send short message to create thread
RESPONSE=$(curl -X POST \
  --data "{\"channel\":\"$SLACK_CHANNEL\",\"blocks\":[
               {\"type\":\"header\",\"text\":{\"type\":\"plain_text\",\"text\":\"$ICON $TITLE\"}},\
               {\"type\":\"section\",\"text\":{\"type\":\"mrkdwn\",\"text\":\"$MESSAGE\"}}\
           ]}" \
  -H "Authorization: Bearer $SLACK_REPORTER_TOKEN" \
  -H "Content-Type: application/json" \
  https://slack.com/api/chat.postMessage)

# if no vulnerabilities found, skip the second message
if grep -q -i "vulnerability" "$REPORT_FILE"; then
  echo "Vulnerabilities found, sending detailed report"
  # get the message timestamp so we can reply to the message
  TIME_STAMP=$(echo $RESPONSE | jq -r '.ts')
  send_to_slack_thread_in_chunks "$REPORT" "$TIME_STAMP"
else
  echo "No vulnerabilities found, skipping second message"
  exit 0
fi

# Remove the file after processing
rm -rf $REPORT_FILE