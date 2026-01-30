#!/bin/bash

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
PROJECT_NAME=$(basename "$PROJECT_DIR")

HOSTNAME=$(hostname)
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

MESSAGE="${1}"

curl -X POST -H 'Content-type: application/json' \
  --data "{
    \"text\": \"${MESSAGE}\",
    \"blocks\": [
      {
        \"type\": \"header\",
        \"text\": {
          \"type\": \"plain_text\",
          \"text\": \"${MESSAGE}\"
        }
      },
      {
        \"type\": \"section\",
        \"fields\": [
          {
            \"type\": \"mrkdwn\",
            \"text\": \"*Project:*\n\`${PROJECT_NAME}\`\"
          },
          {
            \"type\": \"mrkdwn\",
            \"text\": \"*Host:*\n\`${HOSTNAME}\`\"
          },
          {
            \"type\": \"mrkdwn\",
            \"text\": \"*Path:*\n\`${PROJECT_DIR}\`\"
          },
          {
            \"type\": \"mrkdwn\",
            \"text\": \"*Datetime:*\n${TIMESTAMP}\"
          }
        ]
      }
    ]
  }" \
  "$AI_AGENTS_SLACK_WEBHOOK_URL"
