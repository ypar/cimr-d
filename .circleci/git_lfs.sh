#!/bin/bash

set -e -x

# Install git-lfs
cd /tmp
wget https://github.com/git-lfs/git-lfs/releases/download/v2.7.2/git-lfs-linux-386-v2.7.2.tar.gz
mkdir -p git-lfs
cd git-lfs
tar xzf ../git-lfs-linux-386-v2.7.2.tar.gz
sudo ./install.sh

# Pull files in cimr-d
cd ~/cimr-d
git lfs install
git lfs pull
