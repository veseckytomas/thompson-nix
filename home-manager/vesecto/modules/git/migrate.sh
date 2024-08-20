#!/usr/bin/env bash
#   ________
#  /_  __/ /_  ____  ____ ___  ____  _________  ____
#   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
#  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
# /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
#                          /_/
# Tomáš Vesecký
# Email: vesecky@proton.me
# GitHub: veseckytomas
# GitLab: vesecky.tomas

echo "Enter source repository URI:"
read -r source_repo
echo "Please touch the device."
git clone "$source_repo" tmp_repo
cd tmp_repo || exit
echo "Please touch the device."
git fetch -a
for remote in $(git branch -r | grep -v /HEAD); do
    git checkout --track "$remote"
done
git remote remove origin
echo "Enter target repository URI:"
read -r target_repo
git remote add origin "$target_repo"
echo "Please touch the device."
git push --all
cd ..
rm -rf tmp_repo
