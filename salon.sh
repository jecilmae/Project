#! /bin/bash

DB_ARGS=(--username=freecodecamp --dbname=salon)

db_query() {
  psql -X -qAt "${DB_ARGS[@]}" -c "$1"
}

sql_escape() {
  local value="$1"
  printf '%s' "${value//\'/\'\'}"
}

show_services() {
  db_query "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

echo "~~~~~ MY SALON ~~~~~"
echo
echo "Welcome to My Salon, how can I help you?"
echo
show_services

while true; do
  read SERVICE_ID_SELECTED
  if [[ "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=$(db_query "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  else
    SERVICE_NAME=""
  fi

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  echo
  echo "I could not find that service. What would you like today?"
  show_services
done

echo
echo "What's your phone number?"
read CUSTOMER_PHONE
CUSTOMER_PHONE_SQL=$(sql_escape "$CUSTOMER_PHONE")
CUSTOMER_ID=$(db_query "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE_SQL';")

if [[ -z "$CUSTOMER_ID" ]]; then
  echo
  echo "I don't have a record for that phone number, what's your name?"
  read CUSTOMER_NAME
  CUSTOMER_NAME_SQL=$(sql_escape "$CUSTOMER_NAME")
  db_query "INSERT INTO customers (name, phone) VALUES ('$CUSTOMER_NAME_SQL', '$CUSTOMER_PHONE_SQL');"
  CUSTOMER_ID=$(db_query "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE_SQL';")
else
  CUSTOMER_NAME=$(db_query "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;")
fi

echo
echo "What time would you like your $SERVICE_NAME, $CUSTOMER_NAME?"
read SERVICE_TIME
SERVICE_TIME_SQL=$(sql_escape "$SERVICE_TIME")
db_query "INSERT INTO appointments (customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME_SQL');"

echo
echo "I have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."