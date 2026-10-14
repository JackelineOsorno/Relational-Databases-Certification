#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"
secret_number=$((RANDOM % 1000 + 1))
number_of_guesses=0

echo "Enter your username:"
read -r username
username_sql=${username//\'/\'\'}
user_stats=$($PSQL "SELECT games_played || '|' || best_game FROM users WHERE username = '$username_sql';")

if [[ -n $user_stats ]]; then
  IFS='|' read -r games_played best_game <<< "$user_stats"
  echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
else
  echo "Welcome, $username! It looks like this is your first time here."
fi

echo "Guess the secret number between 1 and 1000:"
while read -r guess; do
  if [[ ! $guess =~ ^[+-]?[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  case $guess in
    -*) guess_number=$((-10#${guess#-})) ;;
    +*) guess_number=$((10#${guess#+})) ;;
    *) guess_number=$((10#$guess)) ;;
  esac

  number_of_guesses=$((number_of_guesses + 1))
  if ((guess_number < secret_number)); then
    echo "It's higher than that, guess again:"
  elif ((guess_number > secret_number)); then
    echo "It's lower than that, guess again:"
  else
    break
  fi
done

echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
$PSQL "INSERT INTO users (username, games_played, best_game) VALUES ('$username_sql', 1, $number_of_guesses) ON CONFLICT (username) DO UPDATE SET games_played = users.games_played + 1, best_game = CASE WHEN users.best_game IS NULL OR EXCLUDED.best_game < users.best_game THEN EXCLUDED.best_game ELSE users.best_game END;" >/dev/null