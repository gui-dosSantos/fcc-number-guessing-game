#!/bin/bash

# psql querry
PSQL="psql --username=freecodecamp --dbname=number_guessing_game -t -c"

# the random secret number
SECRET_NUM=$(($RANDOM % 1000 + 1))

# the variable that will keep track of the number of guesses 
NUM_OF_GUESSES=0

# the algorithm that will handle the username input
USERNAME_ALGO(){
  echo Enter your username:
  read NAME_INPUT

  # fetching user info to see if they are already in the database
  USER_INFO=$($PSQL "SELECT username, user_id, games_played, best_game FROM guessers WHERE username='$NAME_INPUT'")

  echo $USER_INFO | while read USERNAME BAR USER_ID BAR GAMES_PLAYED BAR BEST_GAME
  do  
    if [[ -z $USER_INFO ]]
    then
      # output if the user is not in the database
      echo -e "\nWelcome, $NAME_INPUT! It looks like this is your first time here."
    else
      # output if the user is in the database
      echo -e "\nWelcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    fi
  done
}

# function to deal with the guesses
GUESSING_LOOP(){
  read CURRENT_GUESS
  # if the input is not and integer number
  if [[ ! $CURRENT_GUESS =~ ^[0-9]+$ ]]
  then
    echo That is not an integer, guess again:
    GUESSING_LOOP
  # if the input is a number and it's lower than the secret number
  elif [[ $CURRENT_GUESS -lt $SECRET_NUM ]]
  then
    echo "It's higher than that, guess again:"
    NUM_OF_GUESSES=$(($NUM_OF_GUESSES + 1))
    GUESSING_LOOP
  # if the input is a number and it's higher than the secret number
  elif [[ $CURRENT_GUESS -gt $SECRET_NUM ]]
  then
    echo "It's lower than that, guess again:"
    NUM_OF_GUESSES=$(($NUM_OF_GUESSES + 1))
    GUESSING_LOOP
  # if the input is a number and it's equal to the secret number
  elif [[ $CURRENT_GUESS -eq $SECRET_NUM ]]
  then
    NUM_OF_GUESSES=$(($NUM_OF_GUESSES + 1))
    DATABASE_INSERT
    echo "You guessed it in $NUM_OF_GUESSES tries. The secret number was $SECRET_NUM. Nice job!"
  fi
}

# function to deal with database insertions or updates
DATABASE_INSERT(){
  # if the user is not in the database
  if [[ -z $USER_INFO ]]
  then
    USER_INSERT=$($PSQL "INSERT INTO guessers(username, games_played, best_game) VALUES('$NAME_INPUT', 1, $NUM_OF_GUESSES)")
  # if the user is in the database
  else
    echo $USER_INFO | while read USERNAME BAR USER_ID BAR GAMES_PLAYED BAR BEST_GAME
    do
      GAMES_PLAYED=$(($GAMES_PLAYED + 1))
      # if the number of guesses of the current game is lower than the user's best score
      if [[ $NUM_OF_GUESSES -lt $BEST_GAME ]]
      then
        # updates both the games_played and the best_game columns
        UPDATE_USER=$($PSQL "UPDATE guessers SET games_played = $GAMES_PLAYED, best_game = $NUM_OF_GUESSES WHERE user_id=$USER_ID")
      else
        # updates only the games_played column
        UPDATE_USER=$($PSQL "UPDATE guessers SET games_played = $GAMES_PLAYED WHERE user_id=$USER_ID")
      fi
    done
  fi
}

# function that runs the game
GAME(){
  USERNAME_ALGO
  echo -e "\nGuess the secret number between 1 and 1000:"
  GUESSING_LOOP
}

GAME
