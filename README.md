>> HOW TO USE
---
Create a 3 Deployment job in jenkins 
1- deploy-1 script `deploy in pp and switch the traffic to pp`
2- deploy-2- script `deploy the code in prod server only ` 
3- deploy-3 script  ` create ami , create launch template, and create new instance with asg and traffic switch `
---
Update the Variables as per your enviroment. `Deployment TAG is mandatory to update in every Deployment JOB`
---
Install aws cli inside the jenkins server and setup the aws configure cmd there with AWS Access keys
Required access key with full admin rights `Only CLI Access Required`
---

---
# Here is the Deployment setup instructions:
---

# Deployment Setup

This readme provides step-by-step instructions for setting up and deploying your application.
# Deployment Process README

This document outlines the deployment process for a web application to PP (Pre-Production) and PROD (Production) environments using AWS services like EC2, ELB, and CodeDeploy.

## Setup Environment Variables

Before starting the deployment process, ensure that the following environment variables are set:

- `GIT_USERNAME`: Your GitHub username.
- `GIT_VALID_TOKEN`: Your GitHub personal access token with appropriate permissions.
- `DEPLOYMENT_TAG`: Tag/version of the deployment.
- `AMI_NAME`: Name of the Amazon Machine Image (AMI) to be created.
- `AMI_DESCRIPTION`: Description of the AMI.
- `EC2_USER`: Username to SSH into EC2 instances.
- `PP_INSTANCE_ID`: Instance ID of the PP (Pre-Production) server.
- `PROD_INSTANCE_ID`: Instance ID of the PROD (Production) server.
- `LAUNCH_TEMPLATE_ID`: ID of the Launch Template used for EC2 instances.
- `ASG_NAME`: Name of the Auto Scaling Group (ASG) associated with the EC2 instances.
- `ALB_LISTENER_ARN`: ARN of the Application Load Balancer (ALB) listener.
- `PP_TG_ARN`: ARN of the target group for PP environment.
- `PROD_TG_ARN`: ARN of the target group for PROD environment.

Replace the placeholder values with your actual credentials and resource identifiers.

## Deployment Steps

1. **Start the PP Server Instance:** Initiates the PP server instance to begin deployment.

2. **Wait for Instance Status:** Waits until the PP instance passes the status checks before proceeding.

3. **Deploy Code to PP Server:** Connects to the PP server via SSH and deploys the application code from the specified GitHub repository. Additionally, restarts the Nginx service to apply changes.

4. **Check PP Server Health:** Monitors the health status of instances in the PP target group until all are healthy.

5. **Balance Traffic between PP and PROD:** Modifies the ALB listener configuration to distribute incoming traffic evenly between the PP and PROD instances.

6. **Validate Application Integrity:** Waits for a specified duration to ensure the application's stability after the traffic distribution changes.

7. **Repeat Deployment Steps for PROD:** Follows similar steps to deploy the application to the PROD environment.

8. **Create AMI and Update ASG:** Creates a new Amazon Machine Image (AMI) from the PROD instance and updates the Launch Template with the new AMI. It then updates the Auto Scaling Group (ASG) to terminate old instances and launch new instances with the updated configuration.

9. **Stop PP Instance:** Stops the PP instance once deployment is completed and verified.

## Conclusion

This README provides an overview of the deployment process for deploying a web application to both PP and PROD environments using AWS CLI commands. Ensure to set up the required environment variables and follow each step carefully for a successful deployment.
---

---

This readme provides a detailed guide to deploy your application using AWS services and CLI commands.

For any further assistance, Read the PDF attached.

---

Feel free to customize according to your specific deployment process and environment.
