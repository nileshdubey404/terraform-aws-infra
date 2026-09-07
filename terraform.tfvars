
vpc_cidr             = "11.0.0.0/16"
vpc_name             = "aws-infra-jenkins-ap-south-vpc-1"
cidr_public_subnet   = ["11.0.1.0/24", "11.0.2.0/24"]
cidr_private_subnet  = ["11.0.3.0/24", "11.0.4.0/24"]
ap_availability_zone = ["ap-south-1a", "ap-south-1b"]

ec2_ami_id = "ami-01a00762f46d584a1"
public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGdyALoIcMm00SuEMjC5U8ks+G2EA5kT/LCM3b+WcnNB 315ni@LAPTOP-RR2OIRHC"
