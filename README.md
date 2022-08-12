# Claranet
## _Site Reliability Engineering Test - Willian M Silva_

## Features

- Creates a Golden Image.
- Create an internal network with WEB servers, using Golden Image.
- Create bastion instances to access WEB servers.
- Create an ALB with and register the WEB servers for public access.

## Requirements

- Terraform - https://www.terraform.io/
- Packer - https://www.terraform.io/
- AWS setup.
    - Using credentials file - https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html
    - Using environment variables - https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html


## How to use

Adjust the variables for Terraform in the `terraform.tfvars` file.
Adjust the variables for Packer in the `packer_vars.json` file.
Create the environment with the `make apply` command.
Destroy the environment with the `make destroy` command.

## How to access

Access AWS to obtain ALB DNS at:
- EC2 > Load Balancing > Load Balancers > Select the created load balancer, and get the DNS address.

Accessing the instances using the bastion host:
- Add the "PEM" key, created with the same name defined for the environment.
`ssh-add MY_KEY.pem`
- Get the public IP of a bastion host and use SSH to connect.
`ssh -A -i MY_KEY.pem ec2-user@BASTION_PUBLIC_IP`
- When connecting to the bastion host, get the private ip of a WEB instance and use SSH to connect.
`ssh WEB_PRIVATE_IP`
