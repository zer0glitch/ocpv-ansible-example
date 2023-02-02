#!/bin/bash

sudo dnf install podman -y
cd aap

#ansible-navigator run examples/deploy-cnv.yml -m stdout --eei localhost/zer0glitch.ocpv:1.0.0
