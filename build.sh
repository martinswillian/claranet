#!/bin/bash

echo "Build custom AMI"
packer build -var-file=packer_vars.json packer_ami.json

echo "Configure Terraform"
terraform init

echo "Create AWS Environment"
terraform apply -auto-approve
