#!/bin/bash

sudo pip3 install -U pip
sudo pip3 install ansible
sudo pip3 install kubernetes
sudo pip3 install pyyaml 
sudo dnf install python3-jsonpatch -y
sudo pip3 install openshift 
sudo dnf install vim -y
sudo ansible-galaxy collection install kubernetes.core

ansible-playbook  -vv setup-lab-server.yaml  -b
