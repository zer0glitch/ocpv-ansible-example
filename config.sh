#!/bin/bash

sudo pip3 install -U pip

sudo dnf install -y https://vault.centos.org/centos/8/extras/x86_64/os/Packages/centos-release-ansible-29-1-2.el8.noarch.rpm

sudo dnf install -y https://download-ib01.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/p/python3-kubernetes-11.0.0-6.el8.noarch.rpm

sudo dnf install -y https://vault.centos.org/centos/8/BaseOS/x86_64/os/Packages/python3-pyyaml-3.12-12.el8.x86_64.rpm

sudo dnf install -y https://download-ib01.fedoraproject.org/pub/epel/8/Everything/x86_64/Packages/p/python3-openshift-0.11.2-1.el8.noarch.rpm

#sudo pip3 install ansible
#pip3 install kubernetes
#pip3 install pyyaml 
sudo dnf install python3-jsonpatch -y
#pip3 install openshift 
sudo dnf install vim -y
ansible-galaxy collection install kubernetes.core

ansible-playbook  -vv setup-lab-server.yaml  -b
