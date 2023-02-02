### This document is used to describe how to build and use the Ansible Advanced Automation Platform 2 (AAP 2)

## Setup
```
sudo dnf install podman python38 -y
python3.8 -m pip install ansible-builder==1.0.1 --user
python3.8 -m pip install ansible-navigator==1.0.0 --user
```

## Update ansible-navigator.yml
  * update the volume mount source to point to your kube config

## Running a playbook
  * ansible-navigator run **playbook**
  * the configuration will be read from the ansible-navigator.yml


## Building 
```
ansible-builder build -t quay.io/zeroglitch/ocpv-ee:1.0.0
```
