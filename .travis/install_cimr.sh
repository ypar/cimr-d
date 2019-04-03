#!/bin/sh

git clone https://github.com/greenelab/cimr.git

cd cimr

git lfs pull

python3 setup.py build
python3 setup.py install

df -h
free -g
free -gt
vmstat -s

