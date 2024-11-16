
# Deployment Setup Guide 🚀

This guide walks you through setting up a deployment pipeline using Jenkins for deploying your web application to **PP (Pre-Production)** and **PROD (Production)** environments with AWS services.

## 🛠️ Deployment Process Overview

1. **Deploy to PP** – Deploys the app to the PP server and switches traffic to PP.  
2. **Deploy to PROD** – Deploys the code to the PROD server only.  
3. **Create AMI & Launch Template** – Creates a new AMI, launch template, and updates ASG with new instances. Then switches traffic.

## 🚀 Prerequisites

- **Jenkins** with 3 Deployment jobs (one for each step).
- **AWS CLI** installed on Jenkins server.
- **AWS Access Keys** with full admin rights (CLI access required).
- **Environment Variables** configured in Jenkins.

### Mandatory Variables to Set
- **DEPLOYMENT_TAG**: Deployment version/tag (important for all jobs).  
- **GIT_USERNAME**: Your GitHub username.  
- **GIT_VALID_TOKEN**: GitHub personal access token (with required permissions).  
- **AMI_NAME**: AMI name to be created.  
- **AMI_DESCRIPTION**: Description for the AMI.  
- **EC2_USER**: SSH username for EC2 instances.  
- **PP_INSTANCE_ID**: PP server instance ID.  
- **PROD_INSTANCE_ID**: PROD server instance ID.  
- **LAUNCH_TEMPLATE_ID**: Launch Template ID for EC2.  
- **ASG_NAME**: Auto Scaling Group (ASG) name.  
- **ALB_LISTENER_ARN**: ARN for the ALB listener.  
- **PP_TG_ARN**: ARN for the PP target group.  
- **PROD_TG_ARN**: ARN for the PROD target group.

## 🔄 Deployment Steps

### Step 1: **Deploy to PP** (Job 1)

1. **Start PP Server Instance**: Initiates the PP server for deployment.  
2. **Wait for PP Instance to Pass Checks**: Waits until the PP server is healthy.  
3. **Deploy Code to PP Server**: Deploys your app code from GitHub to the PP server via SSH.  
4. **Health Check**: Verifies PP server is healthy in the target group.  
5. **Balance Traffic**: Switches traffic between PP and PROD instances via the ALB listener.

### Step 2: **Deploy to PROD** (Job 2)

1. **Deploy Code to PROD**: Deploys code to the PROD server.  
2. **Health Check**: Verifies the health status of the PROD server.  
3. **Validate Application**: Ensures the app is working after deployment.

### Step 3: **Create AMI & Update ASG** (Job 3)

1. **Create New AMI**: Creates a new AMI from the PROD instance.  
2. **Update Launch Template**: Updates the Launch Template with the new AMI.  
3. **Update ASG**: Terminates old instances and launches new ones with the updated AMI.  
4. **Switch Traffic**: Modifies the ALB listener to shift traffic as needed.

### Step 4: **Stop PP Instance**:  
Stops the PP instance after successful deployment.

---

## ⚙️ How to Configure Jenkins Jobs

1. **Create 3 Jenkins Jobs**:  
   - **deploy-1**: Deploys to PP and switches traffic.  
   - **deploy-2**: Deploys to PROD.  
   - **deploy-3**: Creates AMI, updates launch template, and updates ASG.

2. **Install AWS CLI on Jenkins Server**:  
   - Ensure AWS CLI is configured on the Jenkins server using `aws configure` with your AWS Access Keys.  
   - Required access: **Full Admin Rights** (CLI access only).

3. **Update Variables**:  
   - Set the environment variables as described above before running the deployment jobs.  
   - Make sure **DEPLOYMENT_TAG** is updated in each Jenkins job.

---

## 🎯 Conclusion

This guide provides a simple yet detailed process to deploy your web application to **PP** and **PROD** environments using AWS and Jenkins. Ensure that your environment variables are correctly configured, and follow the steps for each deployment job to achieve successful deployments.

For further help, check the attached PDF or visit the docs at [docs.ahmadraza.in](https://docs.ahmadraza.in).


--- 

