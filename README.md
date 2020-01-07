# Terraform EKS scripts

The terraform scripts in the infrastructure folder create the architecture shown in "created_infrastructure.png"

## Preparation

1. Install AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/install-cliv1.html)
2. Install kubectl (https://kubernetes.io/docs/tasks/tools/install-kubectl/)
3. Install Terraform (https://learn.hashicorp.com/terraform/getting-started/install.html)
4. Configure AWS CLI (https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html). Make sure to assume a role with sufficient rights.


## Creating the remote state S3 bucket (only if not created yet)

1. Navigate to infrastructure\s3_remote_state
2. Change name of S3 bucket (`default = "remote-state-s3"`) in file `variables.tf`. S3 bucket names are globally unique in AWS accross all accounts and namespaces:

`variables.tf:`

```
variable "remote_state_s3" {
    type = string
    default = "remote-state-s3"
}
```
3. Create S3 and DynamoDB:

```
terraform init
terraform apply
```

## Create infrastructure
1. Navigate to infrastructure\test
2. Adjust the name of the remote state S3 bucket (`bucket = "remote-state-s3"`) in `config.tf` according to the S3 bucket you created before / you want to use:

`config.tf:`
```
terraform {
 backend "s3" {
 encrypt = true
 bucket = "remote-state-s3"
 dynamodb_table = "remote-state-dynamo"
 region = "eu-central-1"
 key = "remote-state/test/terraform.tfstate" # <-- Change for new environment (e.g. ../test/.., ../int/.., ../prod/..) !
 }
}
```
3. Create infrastructure:
```
terraform init
terraform apply
```

## Destroy infrastructure
1. Navigate to infrastructure\test
2. Shut down infrastructure:

```
terraform destroy
```

## Deploy example apps


1. Navigate to deployments\test
2. Adjust the name of the remote state S3 bucket (`bucket = "remote-state-s3"`) in `config.tf` according to the S3 bucket you created before / you want to use:

`config.tf:`
```
terraform {
 backend "s3" {
 encrypt = true
 bucket = "remote-state-s3"
 dynamodb_table = "remote-state-dynamo"
 region = "eu-central-1"
 key = "remote-state/test/deployments.tfstate" # <-- Change for new environment (e.g. ../test/.., ../int/.., ../prod/..) !
 }
}
```
3. Create deployments, ClusterIP services and ingress rules:
```
terraform init
terraform apply
```
4. The output shows you the URL for the app which is created with it's own load balancer. You can use it to access the app. You should see something like this:
```
Outputs:

lb_ip = a79df3ccc314d11eaa1c102cdf2cc96d-1772525332.eu-central-1.elb.amazonaws.com
```
5. For the other two apps you find the URL for the general ingress-nginx via:
```
kubectl get services --all-namespaces
```
6. Append /hello or /twitter to the URL to access the apps

## Configuration

In `infrastructure/test/config.tf` you can specify some scaling options for the worker nodes. Additionally you can switch to a different environment by changing 2 lines:
```
 key = "remote-state/test/terraform.tfstate" # <-- Change for new environment (e.g. ../test/.., ../int/.., ../prod/..) !
 default = "test" # <-- To be changed for new environment (e.g. test, int, prod) !
```
This will name all resources accordingly and store the state in a separated path in the S3 bucket.

