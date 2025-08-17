export
AWS_PROFILE := prod
TF_VAR_aws_profile := ${AWS_PROFILE}
EC2_IDS := "$$(terraform -chdir=terraform output -raw instance_ids_space_separated)"


dryrun-infra:
	terraform -chdir=terraform init
	terraform -chdir=terraform plan
	# If "Error: Inconsistent dependency lock file"
	# do: $ aws sso login --profile prod

deploy-infra:
	terraform -chdir=terraform apply

deploy-software:
	ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i ansible/inventory.ini ansible/site.yml
	# OR, manually execute line by line from:
	# ./manual/build.sh


destroy-infra:
	terraform -chdir=terraform destroy


stop-server:
	aws ec2 stop-instances --instance-ids ${EC2_IDS} --profile ${AWS_PROFILE}


start-server:
	aws ec2 start-instances --instance-ids ${EC2_IDS} --profile ${AWS_PROFILE}
