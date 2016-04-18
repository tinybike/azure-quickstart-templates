#!/bin/bash

# print commands and arguments as they are executed
set -x

echo "initializing geth installation"
date
ps axjf

#############
# Parameters
#############

AZUREUSER=$1
HOMEDIR="/home/$AZUREUSER"
VMNAME=`hostname`
echo "User: $AZUREUSER"
echo "User home dir: $HOMEDIR"
echo "vmname: $VMNAME"

#####################
# install tools
#####################
time sudo npm install azure-cli -g
sudo ln -s /usr/bin/nodejs /usr/bin/node
time sudo apt-get update && sudo apt-get install screen -y
time sudo apt-get -y install git

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

###############################
# Fetch Genesis and Private Key
###############################
cd $HOMEDIR
wget https://raw.githubusercontent.com/kevinday/azure-quickstart-templates/master/augur-on-ubuntu/genesis.json
wget https://raw.githubusercontent.com/kevinday/azure-quickstart-templates/master/augur-on-ubuntu/priv_genesis.key

####################
# Setup Geth
####################
geth init genesis.json
echo "password" > pw.txt  #TODO:prompt for separate pw in tempalte, or just pass in one from auguruser?
geth --password pw.txt account import priv_genesis.key
 
#Pregen DAG so miniing can start immediately, no delay between when front end is useable
#mkdir ~/.ethash
#geth makedag 0 ~/.ethash

#start geth+mining using screen
#screen -dmS geth geth --unlock --maxpeers 0 --networkid 1101011 --rpc --rpccorsdomain "*" --mine


####################
#Install Augur Front End
####################
git clone https://github.com/AugurProject/augur.git
#cd augur
#sudo npm install
#sudo npm run build #not needed
#npm start

####################
#Install Augur Contracts
####################
cd $HOMEDIR
git clone https://github.com/AugurProject/augur-core.git


date
echo "completed geth install $$"