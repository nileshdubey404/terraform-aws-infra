# Terraform AWS Infrastructure

> Infrastructure as Code project for provisioning a Jenkins-based AWS environment using **Terraform**.

This project automates the deployment of a complete AWS infrastructure stack using Terraform. It creates a custom VPC with public and private subnets, configures networking and security, launches a Jenkins server on EC2, places it behind an Application Load Balancer, and integrates Route 53 and AWS Certificate Manager for DNS and HTTPS.

The project is designed to demonstrate practical **AWS, Terraform, Linux, Networking, Security Groups, Load Balancing, DNS, SSL/TLS, and Jenkins** concepts.

---

## 🏗️ Architecture

```text
                         Internet
                            │
                            ▼
                    ┌─────────────────┐
                    │    Route 53     │
                    │ jenkins.domain  │
                    └────────┬────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │ Application     │
                    │ Load Balancer   │
                    │                 │
                    │ HTTP :80        │
                    │ HTTPS :443     │
                    └────────┬────────┘
                             │
                             ▼
                 ┌──────────────────────┐
                 │   Target Group       │
                 │      HTTP :8080      │
                 └──────────┬───────────┘
                            │
                            ▼
        ┌─────────────────────────────────────┐
        │               AWS VPC               │
        │          11.0.0.0/16                │
        │                                     │
        │  ┌──────────────────────────────┐   │
        │  │       Public Subnets         │   │
        │  │                              │   │
        │  │  ap-south-1a  ap-south-1b   │   │
        │  │       │                      │   │
        │  │       └───────┐              │   │
        │  │               ▼              │   │
        │  │        Jenkins EC2           │   │
        │  │        Ubuntu Linux          │   │
        │  │        HTTP :8080            │   │
        │  └──────────────────────────────┘   │
        │                                     │
        │  ┌──────────────────────────────┐   │
        │  │       Private Subnets        │   │
        │  │                              │   │
        │  │  ap-south-1a  ap-south-1b   │   │
        │  └──────────────────────────────┘   │
        │                                     │
        │             Internet Gateway        │
        └─────────────────────────────────────┘

             ACM Certificate
                    │
                    ▼
              HTTPS :443
```

---

## 🚀 What This Project Creates

The Terraform configuration is divided into reusable modules for different infrastructure components.

### AWS Resources

* Custom VPC
* 2 Public Subnets
* 2 Private Subnets
* Internet Gateway
* Public Route Table
* Private Route Table
* Route Table Associations
* EC2 Jenkins Server
* EC2 Key Pair
* Security Groups
* Application Load Balancer
* ALB Target Group
* HTTP Listener
* HTTPS Listener
* AWS Certificate Manager certificate
* Route 53 Hosted Zone
* DNS record pointing the Jenkins domain to the ALB

The root Terraform configuration connects these modules together and passes outputs between them.

---

## 🛠️ Technology Stack

| Technology                | Purpose                   |
| ------------------------- | ------------------------- |
| Terraform                 | Infrastructure as Code    |
| AWS                       | Cloud infrastructure      |
| Amazon VPC                | Network isolation         |
| Amazon EC2                | Jenkins server            |
| Application Load Balancer | Traffic distribution      |
| Target Group              | Routes traffic to Jenkins |
| Route 53                  | DNS management            |
| AWS ACM                   | SSL/TLS certificate       |
| Security Groups           | Network access control    |
| Ubuntu Linux              | Jenkins host OS           |
| Jenkins                   | CI/CD automation          |
| Git                       | Version control           |

---

## 📁 Project Structure

```text
terraform-aws-infra/
│
├── certificate-manager/
│   └── main.tf
│
├── hosted-zone/
│   └── main.tf
│
├── jenkins/
│   └── main.tf
│
├── jenkins-runner-script/
│   └── jenkins-installer.sh
│
├── load-balancer/
│   └── main.tf
│
├── load-balancer-target-group/
│   └── main.tf
│
├── networking/
│   └── main.tf
│
├── security-groups/
│   └── main.tf
│
├── main.tf
├── provider.tf
├── variables.tf
├── terraform.tfvars
├── output.tf
├── .gitignore
└── .terraform.lock.hcl
```

---

# 🔧 How It Works

## 1. Networking

Terraform creates a custom VPC with CIDR:

```text
11.0.0.0/16
```

The project uses two Availability Zones:

```text
ap-south-1a
ap-south-1b
```

Public subnets:

```text
11.0.1.0/24
11.0.2.0/24
```

Private subnets:

```text
11.0.3.0/24
11.0.4.0/24
```

The public subnets are associated with a route table containing:

```text
0.0.0.0/0 → Internet Gateway
```

The private subnets currently have their own route table but no NAT Gateway configured.

---

## 2. Jenkins EC2

Terraform provisions an EC2 instance for Jenkins.

Current configuration:

```text
Instance Type: t2.medium
OS: Ubuntu
Jenkins Port: 8080
```

The Jenkins installation is automated through EC2 `user_data`, which executes:

```text
jenkins-runner-script/jenkins-installer.sh
```

The EC2 instance is configured with:

* SSH key pair
* Security groups
* Public IP
* Jenkins installation script
* IMDSv2 required

The Jenkins module explicitly requires IMDSv2 tokens through EC2 metadata options.

---

## 3. Security Groups

The project creates separate security groups for general EC2 access and Jenkins.

### EC2 Security Group

Allows:

```text
SSH    → 22
HTTP   → 80
HTTPS  → 443
```

### Jenkins Security Group

Allows:

```text
Jenkins → 8080
```

The current configuration allows these ingress rules from `0.0.0.0/0`, which should be restricted to trusted CIDRs or security-group references in a production environment.

---

## 4. Application Load Balancer

An Application Load Balancer is created across the public subnets.

Traffic flow:

```text
Client
  │
  ▼
ALB :80 / :443
  │
  ▼
Target Group
  │
  ▼
Jenkins EC2 :8080
```

The target group forwards traffic to the Jenkins EC2 instance on port `8080`.

The ALB module configures:

```text
HTTP Listener  → 80
HTTPS Listener → 443
Target         → Jenkins EC2
```

The HTTPS listener uses an ACM certificate.

---

## 5. Route 53

The project creates/configures a Route 53 hosted zone and points the Jenkins domain toward the Application Load Balancer.

Example:

```text
jenkins.example.com
        │
        ▼
Application Load Balancer
        │
        ▼
Jenkins EC2 :8080
```

The current Terraform configuration uses:

```text
jenkins.nilesh.org
```

as the Jenkins hostname.

> Replace this domain with your own Route 53 hosted zone/domain when deploying the project.

---

## 6. AWS Certificate Manager

AWS Certificate Manager is used to provide an SSL/TLS certificate for the Jenkins domain.

The certificate is connected to the ALB HTTPS listener:

```text
Client
  │
  │ HTTPS :443
  ▼
ALB
  │
  │ ACM Certificate
  ▼
Target Group
  │
  ▼
Jenkins :8080
```

This allows Jenkins to be accessed through HTTPS instead of exposing Jenkins directly to the internet on port `8080`.

---

# ⚙️ Prerequisites

Before deploying the infrastructure, install:

* AWS CLI
* Terraform
* Git
* An AWS account
* An IAM user/role with sufficient permissions
* A registered domain if you want Route 53 + ACM HTTPS
* SSH key pair

Verify the installations:

```bash
terraform version
aws --version
git --version
```

Configure AWS credentials:

```bash
aws configure
```

Then verify:

```bash
aws sts get-caller-identity
```

---

# 📥 Clone the Repository

```bash
git clone https://github.com/nileshdubey404/terraform-aws-infra.git
cd terraform-aws-infra
```

---

# 🔐 Configure Variables

The project uses variables for:

```text
VPC CIDR
VPC name
Public subnet CIDRs
Private subnet CIDRs
Availability Zones
EC2 AMI ID
SSH public key
```

Example:

```hcl
vpc_cidr              = "11.0.0.0/16"
vpc_name              = "aws-infra-jenkins-vpc"
cidr_public_subnet    = ["11.0.1.0/24", "11.0.2.0/24"]
cidr_private_subnet   = ["11.0.3.0/24", "11.0.4.0/24"]
ap_availability_zone  = ["ap-south-1a", "ap-south-1b"]
ec2_ami_id            = "<YOUR_AMI_ID>"
public_key            = "<YOUR_SSH_PUBLIC_KEY>"
```

The repository currently contains environment-specific values in `terraform.tfvars`; replace them with your own values before deployment.

---

# 🚀 Terraform Deployment

## Step 1 — Initialize Terraform

```bash
terraform init
```

This downloads the required Terraform providers and initializes the working directory.

---

## Step 2 — Format Terraform Code

```bash
terraform fmt -recursive
```

---

## Step 3 — Validate Configuration

```bash
terraform validate
```

Expected result:

```text
Success! The configuration is valid.
```

---

## Step 4 — Review Infrastructure Changes

```bash
terraform plan
```

Review the resources Terraform intends to create.

---

## Step 5 — Deploy Infrastructure

```bash
terraform apply
```

Confirm with:

```text
yes
```

Terraform will then provision the AWS infrastructure.

---

# 🔍 Verify the Deployment

After deployment, verify the resources from AWS Console or CLI.

### VPC

```bash
aws ec2 describe-vpcs
```

### EC2

```bash
aws ec2 describe-instances
```

### Load Balancer

```bash
aws elbv2 describe-load-balancers
```

### Target Group

```bash
aws elbv2 describe-target-groups
```

### Route 53

```bash
aws route53 list-hosted-zones
```

---

# 🌐 Access Jenkins

Once the infrastructure is deployed, Jenkins can be accessed through the ALB.

Example:

```text
https://jenkins.example.com
```

The request flow is:

```text
Browser
   │
   │ HTTPS
   ▼
Route 53
   │
   ▼
Application Load Balancer
   │
   ▼
Target Group
   │
   ▼
Jenkins EC2
   │
   ▼
Jenkins :8080
```

---

# 🧹 Destroy Infrastructure

To remove the infrastructure created by Terraform:

```bash
terraform destroy
```

Review the resources carefully and confirm:

```text
yes
```

> Always run `terraform plan` or review the destroy plan carefully before removing infrastructure.

---

# 🔐 Security Considerations

This repository is primarily a learning/portfolio project.

Before using a similar architecture in production, improve the following areas:

### 1. Restrict SSH

Current configuration permits:

```text
0.0.0.0/0 → TCP/22
```

Production configuration should restrict SSH to trusted IP addresses or preferably use AWS Systems Manager where appropriate.

### 2. Restrict Jenkins Port

The current configuration exposes:

```text
0.0.0.0/0 → TCP/8080
```

A production architecture should avoid directly exposing Jenkins `8080` to the internet.

Ideally:

```text
Internet
   │
   ▼
ALB :443
   │
   ▼
Jenkins :8080
```

with the Jenkins security group allowing port `8080` only from the ALB security group.

### 3. Protect Terraform State

Do not commit sensitive Terraform state files.

For a production setup, use a remote backend such as:

```text
S3 + DynamoDB/state locking equivalent
```

with appropriate IAM controls.

### 4. Use Secrets Management

Do not store credentials, passwords, tokens, or private keys in Git.

Consider:

* AWS Secrets Manager
* AWS Systems Manager Parameter Store
* IAM roles
* GitHub Actions secrets

---

# 🧠 DevOps Concepts Demonstrated

This project demonstrates practical understanding of:

### Infrastructure as Code

```text
Terraform
├── Variables
├── Modules
├── Resources
├── Outputs
└── Dependencies
```

### AWS Networking

```text
VPC
├── Public Subnets
├── Private Subnets
├── Route Tables
└── Internet Gateway
```

### Load Balancing

```text
ALB
└── Target Group
    └── Jenkins EC2
```

### DNS

```text
Route 53
    ↓
ALB DNS
```

### SSL/TLS

```text
ACM
    ↓
ALB HTTPS Listener :443
```

### CI/CD Foundation

```text
Jenkins
    ↓
Future CI/CD Pipelines
```

---

# 📚 Terraform Concepts Used

This project uses several important Terraform concepts:

* Providers
* Variables
* Variable files
* Modules
* Resource dependencies
* Module outputs
* `templatefile()`
* Lists
* `tolist()`
* Terraform state
* Terraform plan
* Terraform apply
* Terraform destroy
* Infrastructure modularization

The root module passes networking, security-group, Jenkins, target-group, ALB, DNS, and certificate outputs between modules.

---

# 🎯 Project Objective

The main objective of this project is to demonstrate how a DevOps engineer can use Terraform to provision and connect multiple AWS services into a working infrastructure environment instead of manually creating each resource through the AWS Console.

The project focuses on:

```text
Terraform
    ↓
AWS Infrastructure
    ↓
Networking
    ↓
EC2
    ↓
Jenkins
    ↓
Load Balancer
    ↓
DNS
    ↓
HTTPS
```

---

# 🔮 Future Improvements

Planned improvements for a more production-oriented architecture:

* [ ] Remote Terraform backend
* [ ] State locking
* [ ] NAT Gateway
* [ ] Private Jenkins EC2 deployment
* [ ] ALB → EC2 security-group referencing
* [ ] Remove direct public access to Jenkins `8080`
* [ ] Restrict SSH access
* [ ] Auto Scaling Group
* [ ] Multi-instance Jenkins architecture
* [ ] CloudWatch monitoring
* [ ] CloudWatch alarms
* [ ] IAM roles instead of static credentials
* [ ] Secrets Manager integration
* [ ] Terraform CI/CD using GitHub Actions
* [ ] Terraform security scanning
* [ ] Terraform linting
* [ ] Separate development/staging/production environments
* [ ] Reusable Terraform modules
* [ ] Automated infrastructure testing

---

# 👨‍💻 Author

**Nilesh Dubey**

DevOps / Cloud Engineering Portfolio Project

GitHub:
https://github.com/nileshdubey404

---

# ⭐ If You Find This Project Useful

If this project helped you understand Terraform and AWS infrastructure, consider giving the repository a ⭐ on GitHub.

---

## 📄 License

This project is intended for educational and portfolio purposes.
