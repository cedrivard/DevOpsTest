# DevOpsTest
This is a terraform file that can be used to create a web cluster on AWS.

The files in the html/ directory are used as a sample page.

Steps required to have the web service deployed:
- Download terraform from https://www.terraform.io/ and install it in your $PATH
- Get an AWS Account with its *Access Key ID* and *Secret Access Key*
- Set the environment accordingly:
```
# export AWS_ACCESS_KEY_ID=(your access key id)
# export AWS_SECRET_ACCESS_KEY=(your secret access key)
```
- run terraform in the directory that cointains the .tf file

# Configuration and variables
In order to make the cluster scale with the http traffic, one can change the max number of concurrent instances being run on the cluster and the type of instances.

By default *t2.micro* is used but other type with more vCPU could be used instead.
*max_ec2_count* is set to 50 by default but could be increased to handle an higher workload.

For exmaple:
```
# terraform apply -var max_ec2_count=100
```
