#!/bin/bash
set -e # Bail on first sign of trouble

echo "Running A2 deployment script... make sure you have read the lab notes and the prerequisites in the script itself."

echo "Testing AWS credentials"
aws sts get-caller-identity

cd infra

path_to_ssh_key="my_A2_key" # Also reflected in you.auto.tfvars, but with ".pub" suffix
echo "Creating SSH keypair ${path_to_ssh_key}..."
ssh-keygen -C ubuntu@A2 -f "${path_to_ssh_key}" -N ''

echo "Initialising Terraform..."
terraform init
echo "Validating Terraform configuration..."
terraform validate
echo "Running terraform apply, get ready to review and approve actions..."
terraform apply -auto-approve

#return the variable/ip for app and db
echo "Raw output of instance IPs"
terraform output -raw db_public_hostname
terraform output -raw app_public_hostname

#apply the output of app and db hostname to variables
echo "Outputing hostname as .json"
terraform output -json > outputs.json
db_public_hostname=$(jq -r '.db_public_hostname.value' outputs.json)
app_public_hostname=$(jq -r '.app_public_hostname.value' outputs.json)

#run db playbook yml
echo "Running ansible to configure app - db"
export ANSIBLE_HOST_KEY_CHECKING=False
cd .. # Back to root of lab
ansible-playbook ansible/db-playbook.yml -i infra/ansible-inventory.yml --private-key "infra/my_A2_key" -auto-approve

#run app playbook yml
echo "Running ansible to configure App"
ansible-playbook ansible/app-playbook.yml -e "db_public_hostname=${db_public_hostname}" -i infra/ansible-inventory.yml --private-key "infra/my_A2_key" -auto-approve

#run app-clone playbook yml
echo "Running ansible to configure App Clone"
ansible-playbook ansible/app-clone-playbook.yml -e "db_public_hostname=${db_public_hostname}" -i infra/ansible-inventory.yml --private-key "infra/my_A2_key" -auto-approve
