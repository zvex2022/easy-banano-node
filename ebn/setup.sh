#!/bin/bash

# goto script dir
cd "$(dirname "$0")"

echo "== Cloning Banano Node Monitor"
git -C /opt/bananoNodeMonitor pull || git clone https://github.com/BananoTools/bananoNodeMonitor.git /opt/bananoNodeMonitor

echo "== Updating Docker images"
sudo docker pull bananocoin/banano
sudo docker pull php:7.2-apache

echo "== Starting Docker containers"
sudo docker-compose up -d

echo "== Take a deep breath..."
# we need this as the node is crashing if we go on too fast
sleep 5s

