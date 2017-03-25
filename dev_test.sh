#!/bin/bash

while true; do
  inotifywait --exclude \..*\.sw. -re modify .
  clear
  mix compile &&
    mix dialyzer --halt-exit-status &&
    mix test
done
