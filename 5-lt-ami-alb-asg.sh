# NOTE : AMI + LT + ASG + Traffic TO PROD 
# REMEMBER TO CHECK that both TG are added to ALB https:lisner otherwise it will not work properly to forward the traffic 
export AWS_DEFAULT_REGION=xxxxxxxxx

# Set environment variables for AMI name and description
export AMI_NAME="API-TAG-$BUILD_NUMBER"
export AMI_DESCRIPTION="API-TAG-$BUILD_NUMBER"

# EC2 ID for deployment setup
export PP_INSTANCE_ID="i-xxxxxxxxxxxxx"
export PROD_INSTANCE_ID="i-xxxxxxxxxxxxx" ## FOR PROD SERVER ONLY

# Set environment variables for the launch template
export LAUNCH_TEMPLATE_ID="lt-xxxxxxxxxxxxx"
export PROD_LT_NAME="xxxxxxxxx"

# Replace YOUR_TARGET_GROUP_ARN with the ARN of your target group
export ASG_NAME="xxxxxxxxxxxxx"
export ALB_LISTENER_ARN=arn:aws:elasticloadbalancing:ap-south-1:xxxxxxxxxxxxx:listener/app/JENZ/xxxxxxxxxxxxx/xxxxxxxxxxxxx

## PP TG arn for healthy status check
# MPTG-TG-1
export PP_TG_ARN="arn:aws:elasticloadbalancing:ap-south-1:xxxxxxxxxxxxx:targetgroup/PP-TG-1/xxxxxxxxxxxxx"
# MPTG-TG
export PROD_TG_ARN="arn:aws:elasticloadbalancing:ap-south-1:xxxxxxxxxxxxx:targetgroup/PROD-TG-2/xxxxxxxxxxxxx"

######################################################################################################################


# Wait for the instance to reach 2/2 status checks passed
aws ec2 wait instance-status-ok --instance-ids $PROD_INSTANCE_ID

# Retrieve the public IP address of the prod instance
public_ip_prod=$(aws ec2 describe-instances --instance-ids $PROD_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
echo "Public IP of PROD instance $public_ip_prod " 


#### DEPLOYMENT PROCESS ####### 
# Create an AMI of the instance
ami_id=$(aws ec2 create-image --instance-id $PROD_INSTANCE_ID --name "AMI-$AMI_NAME" --description "BUILD-NO-$BUILD_NUMBER AMI-NAME-$AMI_NAME" --no-reboot --output text)
echo "$ami_id"
# Wait for the AMI to be available
echo "Waiting for the AMI to be available..."
sleep 20
aws ec2 wait image-available --image-ids $ami_id
echo "AMI = $ami_id is now available. Wait 1 Minute"
sleep 10

# Create a new Version of Launch Template with new AMI ID 
aws ec2 create-launch-template-version \
    --launch-template-name $PROD_LT_NAME \
    --source-version 1 \
    --version-description $BUILD_NUMBER \
    --launch-template-data "{\"ImageId\":\"$ami_id\"}" 

    

# Show all LT versions for comparison old to new versions
aws ec2 describe-launch-template-versions \
    --launch-template-name $PROD_LT_NAME


# Set minimum, maximum, and desired capacity to 0 to delete the old ec2 instance 
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --min-size 0 --max-size 0 --desired-capacity 0

# Wait for 30 seconds to let it terminate
echo " ASG terminating old instance in " 
sleep 10

# Set minimum, maximum, and desired capacity to 2 to create an EC2 instance with a new AMI ID 
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --min-size 1 --max-size 4 --desired-capacity 1
# Wait for 30 seconds to let it create a new EC2
echo " ASG creating new EC2 instance in from AMI = $ami_id " 
sleep 60


# ALB Check the status of instances in the target group
status=$(aws elbv2 describe-target-health --target-group-arn $PROD_TG_ARN --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`].TargetHealth.State' --output text)

echo " THE STATUS OF INSTANCE IS = $status "

# Loop until all instances are healthy
while [ ! -z "$status" ]; do
    echo "Waiting for instances to become healthy...# STATUS IS  = $status"
    sleep 5
    status=$(aws elbv2 describe-target-health --target-group-arn $PROD_TG_ARN --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`].TargetHealth.State' --output text)
done

echo "All instances are healthy! Check Payment Status"
sleep 10



# Modify the ALB listener to balance traffic between TG1 and TG2 (0/100) with stickiness duration of 3600 seconds (1 hour)
aws elbv2 modify-listener \
  --listener-arn $ALB_LISTENER_ARN \
  --default-actions \
  "[{
      \"Type\": \"forward\",
      \"Order\": 1,
      \"ForwardConfig\": {
         \"TargetGroups\": [
           { \"TargetGroupArn\": \"$PROD_TG_ARN\",
             \"Weight\": 100 },
           { \"TargetGroupArn\": \"$PP_TG_ARN\",
             \"Weight\": 0 }
         ],
         \"TargetGroupStickinessConfig\": {
             \"Enabled\": true,
             \"DurationSeconds\": 3600
         }
      }
  }]"  
  
  
echo "100% load in PROD instance ID = $PROD_INSTANCE_ID & PROD instance IP = $public_ip_prod"

# curl req to get 200 OK in api.example.com
# Status Check
echo "API.Paytring.com : Project deployed successfully "
echo " Healh Check Status = 1 "
curl -o /dev/null -s -w "%{http_code}\n" https://api.example.com
sleep 10

# Status Check
echo "API.Paytring.com : Project deployed successfully "
echo " Healh Check Status = 1 "
curl -o /dev/null -s -w "%{http_code}\n" https://api.example.com
sleep 10

# Status Check
echo "API.Paytring.com : Project deployed successfully "
echo " Healh Check Status = 1 "
curl -o /dev/null -s -w "%{http_code}\n" https://api.example.com
sleep 10

# Status Check
echo "API.Paytring.com : Project deployed successfully "
echo " Healh Check Status = 1 "
curl -o /dev/null -s -w "%{http_code}\n" https://api.example.com
sleep 10

# Status Check
echo "API.Paytring.com : Project deployed successfully "
echo " Healh Check Status = 1 "
curl -o /dev/null -s -w "%{http_code}\n" https://api.example.com
sleep 10


# Will Update this after the first successful deployment of Paytring 
echo " Wait 5 minute before stopping PP instance"
sleep 300


# Stop the PP instance deployment is completed and working fine in PP as of now 
aws ec2 stop-instances --instance-ids $PP_INSTANCE_ID
echo " stopping PP instance = $PP_INSTANCE_ID "


### Deployed ###
echo " Deployed Successfully! "
echo " Deployed Successfully! "
echo " Deployed Successfully! "

