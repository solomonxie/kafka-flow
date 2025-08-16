export
AWS_PROFILE := prod
TF_VAR_aws_profile := ${AWS_PROFILE}
EC2_ID := "$$(terraform -chdir=deploy/terraform output -raw instance_id)"


deploy-infra:
	terraform -chdir=deploy/terraform apply


destroy-infra:
	terraform -chdir=deploy/terraform destroy


stop-server:
	aws ec2 stop-instances --instance-ids ${EC2_ID} --profile ${AWS_PROFILE}


start-server:
	aws ec2 start-instances --instance-ids ${EC2_ID} --profile ${AWS_PROFILE}
