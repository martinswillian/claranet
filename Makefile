help:
	@echo ""
	@echo "Set the variables in the 'terraform.tfvars' and 'packer_vars.json' files."
	@echo "Then run 'make apply', or 'make destroy'."
	@echo ""

apply:
	@echo ""
	@echo "Creating custom AMI..."
	@packer build -var-file=packer_vars.json packer_ami.json
	@echo ""
	@echo "Configuring Terraform..."
	@terraform init
	@echo ""
	@echo "Creating AWS environment..."
	@terraform apply -auto-approve

destroy:
	@echo ""
	@echo "Deleting AWS environment..."
	@terraform destroy -auto-approve
