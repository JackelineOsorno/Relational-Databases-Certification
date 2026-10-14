#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon -q -t -A"

printf '\n~~~~~ MY SALON ~~~~~\n\n'
printf 'Welcome to My Salon, how can I help you?\n\n'

while true; do
  while IFS='|' read -r SERVICE_ID SERVICE_NAME; do
    printf '%s) %s\n' "$SERVICE_ID" "$SERVICE_NAME"
  done < <($PSQL -c 'SELECT service_id, name FROM services ORDER BY service_id' | tr '\t' '|')

  read SERVICE_ID_SELECTED
  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$($PSQL -c "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
  else
    SERVICE_NAME=
  fi

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  printf '\nI could not find that service. What would you like today?\n'
done

printf "\nWhat's your phone number?\n"
read CUSTOMER_PHONE
PHONE_SQL=${CUSTOMER_PHONE//\'/\'\'}
CUSTOMER_ID=$($PSQL -c "SELECT customer_id FROM customers WHERE phone = '$PHONE_SQL'")

if [[ -z "$CUSTOMER_ID" ]]; then
  printf '\nI don\x27t have a record for that phone number, what\x27s your name?\n'
  read CUSTOMER_NAME
  NAME_SQL=${CUSTOMER_NAME//\'/\'\'}
  CUSTOMER_ID=$($PSQL -c "INSERT INTO customers (name, phone) VALUES ('$NAME_SQL', '$PHONE_SQL') RETURNING customer_id")
else
  CUSTOMER_NAME=$($PSQL -c "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID")
fi

printf '\nWhat time would you like your %s, %s?\n' "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME
TIME_SQL=${SERVICE_TIME//\'/\'\'}
$PSQL -c "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$TIME_SQL')" >/dev/null

printf '\nI have put you down for a %s at %s, %s.\n' "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
