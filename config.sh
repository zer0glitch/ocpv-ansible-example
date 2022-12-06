#!/bin/bash

sudo dnf install ansible -y
sudo dnf install python3-kubernetes -y
sudo dnf install python3-pyyaml -y
sudo dnf install python3-jsonpatch -y
sudo dnf install python3-openshift -y
sudo dnf install vim -y
sudo ansible-galaxy collection install kubernetes.core

ansible-playbook  -vv setup-lab-server.yaml  -b
