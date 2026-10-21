#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -q"

secret_number=$(( RANDOM % 1000 + 1 ))

echo "Enter your username:"
read -r username

user_id=$($PSQL -v username="$username" <<'SQL'
SELECT user_id FROM users WHERE username = :'username';
SQL
)

if [[ -z "$user_id" ]]; then
  $PSQL -v username="$username" <<'SQL'
INSERT INTO users(username) VALUES (:'username') ON CONFLICT (username) DO NOTHING;
SQL
  user_id=$($PSQL -v username="$username" <<'SQL'
SELECT user_id FROM users WHERE username = :'username';
SQL
)
fi

user_stats=$($PSQL -v user_id="$user_id" <<'SQL'
SELECT COUNT(*), COALESCE(MIN(number_of_guesses), 0) FROM games WHERE user_id = :'user_id';
SQL
)
IFS='|' read -r games_played best_game <<< "$user_stats"

if (( games_played == 0 )); then
  echo "Welcome, $username! It looks like this is your first time here."
else
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
fi

echo "Guess the secret number between 1 and 1000:"
read -r guess

number_of_guesses=0
while true; do
  if [[ ! "$guess" =~ ^-?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    read -r guess
    continue
  fi

  if [[ "$guess" == -* ]]; then
    guess_number=$((-10#${guess#-}))
  else
    guess_number=$((10#$guess))
  fi
  ((number_of_guesses++))

  if (( guess_number == secret_number )); then
    break
  elif (( guess_number > secret_number )); then
    echo "It's lower than that, guess again:"
  else
    echo "It's higher than that, guess again:"
  fi
  read -r guess
done

$PSQL -v user_id="$user_id" -v number_of_guesses="$number_of_guesses" <<'SQL'
INSERT INTO games(user_id, number_of_guesses) VALUES (:'user_id', :'number_of_guesses');
SQL

echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"