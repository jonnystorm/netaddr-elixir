#!/bin/bash

while true
do
  inotifywait --exclude \..*\.sw. -re modify .
  clear
  mix clean &&
    mix test &&
    env MIX_ENV=test mix dialyzer --halt-exit-status
done
