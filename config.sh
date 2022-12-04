#!/bin/bash

sudo pip3 install ansible
sudo pip3 install kubernetes
sudo pip3 install PyYAML
sudo pip3 install jsonpatch
sudo pip3 install openshift
yum install vim -y



ansible-playbook  -vv setup-lab-server.yml  -b
