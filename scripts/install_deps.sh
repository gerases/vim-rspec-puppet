#!/bin/sh

# Installs dependencies when running under Travis-CI
wget https://github.com/kana/vim-vspec/tarball/master -O /tmp/vspec.tar.gz
mkdir vspec
tar -xzvf /tmp/vspec.tar.gz --strip=1 -C vspec
sudo apt-get -y install vim
