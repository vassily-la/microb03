#!/bin/sh
workon flsk
sleep 1
source envs/local.env
sleep 1
flask run
