#!/bin/bash

sudo pip3 install -U pip
sudo pip3 install ansible==2.10
sudo pip3 install kubernetes
sudo pip3 install openshift
sudo pip3 install jsonpath
sudo pip3 install -U kubernetes==12.0.0
#sudo pip3 install -U pyyml

ansible-playbook  -vv examples/setup-ocpv-ansible-enviornment.yml  -b
ansible-playbook  -vv examples/setup-ocpv-user.yml
ansible-playbook  -vv examples/setup-lab-server.yml  -b
#ansible-playbook  -vv deploy-cnv.yml 
