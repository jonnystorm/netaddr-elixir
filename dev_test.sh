#!/bin/bash

function run
{
  mix clean &&
    MIX_ENV=test ERL_COMPILER_OPTIONS=bin_opt_info \
      mix compile --force &&
    mix test --stale --cover &&
    env MIX_ENV=test mix dialyzer
}

clear
run

while true
do
  inotifywait --exclude \..*\.sw. -re modify .
  clear
  run
done
