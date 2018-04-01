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

if [ -f /opt/bananoNodeMonitor/modules/config.php ]; then

  echo "== Banano node directory exists, skipping initialization..."

else

  echo "== Creating wallet"
  wallet=$(docker exec ebn_bananonode_1 /usr/bin/bananode --wallet_create)

  echo "== Creating account"
  account=$(docker exec ebn_bananonode_1 /usr/bin/bananode --account_create --wallet=$wallet | cut -d ' ' -f2)

  echo "== Creating monitor config"
  cp /opt/bananoNodeMonitor/modules/config.sample.php /opt/bananoNodeMonitor/modules/config.php

  echo "== Modifying the monitor config"

  # uncomment account
  sed -i -e 's#// $nanoNodeAccount#$nanoNodeAccount#g' /opt/bananoNodeMonitor/modules/config.php

  # replace account
  sed -i -e "s/xrb_1f56swb9qtpy3yoxiscq9799nerek153w43yjc9atoaeg3e91cc9zfr89ehj/$account/g" /opt/bananoNodeMonitor/modules/config.php

  # uncomment ip
  sed -i -e 's#// $nanoNodeRPCIP#$nanoNodeRPCIP#g' /opt/bananoNodeMonitor/modules/config.php

  # replace ip
  sed -i -e 's#\[::1\]#ebn_bananonode_1#g' /opt/bananoNodeMonitor/modules/config.php

  # uncomment port
  sed -i -e 's#// $nanoNodeRPCPort#$nanoNodeRPCPort#g' /opt/bananoNodeMonitor/modules/config.php

  # replace port
  sed -i -e 's#7076#7072#g' /opt/bananoNodeMonitor/modules/config.php

  echo "== Disabling RPC logging"
  sed -i -e 's#"log_rpc": "true"#"log_rpc": "false"#g' ~/Banano/config.json

  echo "== Opening Banano Node Port"
  sudo ufw allow 7071

  echo "== Restarting Banano node container"
  sudo docker restart ebn_bananonode_1

  echo "== Just some final magic..."
  # restart because we changed the config.json
  # and the node might be unresponsive at first
  sleep 5s

  echo ""

  echo -e "=== \e[31mYOUR WALLET SEED\e[39m ==="
  echo "Please write down your wallet seed to a piece of paper and store it safely!"
  docker exec ebn_bananonode_1 /usr/bin/bananode --wallet_decrypt_unsafe --wallet=$wallet
  echo -e "=== \e[31mYOUR WALLET SEED\e[39m ==="

fi

serverip=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -vE '^(192\.168|10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|127\.0\.0\.1)')

echo ""
echo "All done! *yay*"
echo "View your Banano Node Monitor at http://$serverip"
echo ""