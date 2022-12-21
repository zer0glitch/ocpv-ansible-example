#!/bin/bash

sudo pip3 install -U pip
sudo pip3 install ansible
sudo pip3 install kubernetes

ansible-playbook  -vv setup-ocpv-ansible-enviornment.yaml  -b
ansible-playbook  -vv setup-ocpv-user.yaml
#ansible-playbook  -vv setup-lab-server.yaml  -b
#ansible-playbook  -vv deploy-cnv.yaml 
