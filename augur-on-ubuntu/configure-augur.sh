#!/bin/bash

# print commands and arguments as they are executed
set -x

echo "starting augur installation"
date

#############
# Parameters
#############

AZUREUSER=$1
LOCATION=$2
VMNAME=`hostname`
HOMEDIR="/home/$AZUREUSER"
ETHEREUM_HOST_RPC="http://${VMNAME}.${LOCATION}.cloudapp.azure.com:8545"
echo "User: $AZUREUSER"
echo "User home dir: $HOMEDIR"
echo "vmname: $VMNAME"

cd $HOMEDIR

#####################
# install tools
#####################
time sudo apt-get install -y build-essential automake pkg-config libtool libffi-dev libgmp-dev
time sudo apt-get -y install git
time sudo apt-get -y install libssl-dev

####################
# Intsall Geth
####################
time sudo apt-get install -y software-properties-common
time sudo add-apt-repository -y ppa:ethereum/ethereum
time sudo add-apt-repository -y ppa:ethereum/ethereum-dev
time sudo apt-get update
time sudo apt-get install -y ethereum

####################
# Install Serpent
####################
time sudo apt-get install -y python-dev
time sudo apt-get install -y python-pip
time sudo pip install ethereum-serpent
time sudo pip install ethereum
time sudo pip install requests --upgrade
time sudo pip install pyethapp

time sudo apt-get update

###############################
# Fetch Genesis and Private Key
###############################
sudo -u $AZUREUSER wget https://raw.githubusercontent.com/kevinday/azure-quickstart-templates/master/augur-on-ubuntu/genesis.json
sudo -u $AZUREUSER wget https://raw.githubusercontent.com/kevinday/azure-quickstart-templates/master/augur-on-ubuntu/priv_genesis.key
sudo -u $AZUREUSER wget https://raw.githubusercontent.com/kevinday/azure-quickstart-templates/master/augur-on-ubuntu/mining_toggle.js
sudo -u $AZUREUSER wget https://raw.githubusercontent.com/kevinday/azure-quickstart-templates/master/augur-on-ubuntu/geth.conf
sudo -u $AZUREUSER wget https://raw.githubusercontent.com/kevinday/azure-quickstart-templates/master/augur-on-ubuntu/augur_ui.conf
sudo -u $AZUREUSER sed -i "s/auguruser/$AZUREUSER/g" geth.conf
sudo -u $AZUREUSER sed -i "s/auguruser/$AZUREUSER/g" augur_ui.conf

touch /var/log/geth.sys.log
touch /var/log/augur_ui.sys.log
chown $AZUREUSER /var/log/geth.sys.log
chown $AZUREUSER /var/log/augur_ui.sys.log

####################
# Setup Geth
####################
sudo -i -u $AZUREUSER geth init genesis.json 
pw=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-16};echo;`
sudo -u $AZUREUSER echo $pw > pw.txt
sudo -i -u $AZUREUSER geth --password pw.txt account import priv_genesis.key

#make geth a service, turn on.
cp geth.conf /etc/init/
start geth

#Pregen DAG so miniing can start immediately
sudo -u $AZUREUSER mkdir .ethash
sudo -i -u $AZUREUSER geth makedag 0 .ethash

####################
#Install Augur Contracts
####################
sudo -i -u $AZUREUSER git clone https://github.com/AugurProject/augur-core.git
cd  augur-core/load_contracts
python load_contracts.py
cd ..

####################
#Make a swap file (node can get hungry)
####################
fallocate -l 128MiB /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

####################
#Install Augur Front End
####################
sudo -i -u $AZUREUSER git clone https://github.com/AugurProject/augur.git
sudo -i -u $AZUREUSER mkdir ui
sudo -i -u $AZUREUSER cp -r augur/azure/2.0.0 ui/2.0.0
rm -rf augur
#TODO: search/replace UI.

#allow nodejs to run on port 80 w/o sudo
setcap 'cap_net_bind_service=+ep' /usr/bin/nodejs

#TODO: modify to serve static files.
#Make augur_ui a service, turn on.
#cp augur_ui.conf /etc/init/
#start augur_ui 

date
echo "completed augur install $$"
