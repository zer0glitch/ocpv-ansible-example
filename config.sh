#!/bin/bash

sudo pip3 install -U pip
sudo pip3 install ansible==2.10
sudo pip3 install kubernetes
sudo pip3 install openshift
sudo pip3 install jsonpath
sudo pip3 install -U kubernetes==12.0.0
#sudo pip3 install -U pyyaml

ansible-playbook  -vv setup-ocpv-ansible-enviornment.yaml  -b
ansible-playbook  -vv setup-ocpv-user.yaml
ansible-playbook  -vv setup-lab-server.yaml  -b
#ansible-playbook  -vv deploy-cnv.yaml 
