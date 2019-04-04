#!/bin/sh

git config --global user.email "cimrroot@gmail.com"
git config --global user.name "cimrroot"
git config --global push.default simple

git remote rm origin
git remote add origin "https://${CIMRROOT_TOKEN}@github.com/greenelab/cimr-d.git" > /dev/null 2>&1

git checkout master
git add processed_data/*
git commit --author="cimrroot <cimrroot@gmail.com>" -m "Travis build: $TRAVIS_BUILD_NUMBER"

git push --force --quiet origin master

