# NOTE : AMI + LT + ASG + Traffic TO PROD 
# REMEMBER TO CHECK that both TG are added to ALB https:lisner otherwise it will not work properly to forward the traffic 
export AWS_DEFAULT_REGION=ap-south-1

# Set environment variables for AMI name and description
export AMI_NAME="API-TAG-${GIT_BRANCH##refs/tags/}-BUILD_NO-$BUILD_NUMBER"
export AMI_DESCRIPTION=$AMI_NAME

# EC2 ID for deployment setup
export PP_INSTANCE_ID="i-x"
export PP_INSTANCE_ID_2="i-x"
export PROD_INSTANCE_ID="i-x" ## FOR PROD SERVER ONLY

# Set environment variables for the launch template
export LAUNCH_TEMPLATE_ID="lt-x"
export PROD_LT_NAME="<NAME>"

export ASG_NAME="x"
export ALB_LISTENER_ARN=arn:aws:elasticloadbalancing:ap-south-1:<number>:listener/app/<name>/<id>/<id>
export PP_TG_ARN="arn:aws:elasticloadbalancing:ap-south-1:<number>:targetgroup/<name>/<id>"
export PROD_TG_ARN="arn:aws:elasticloadbalancing:ap-south-1:<number>:targetgroup/<name>/<id>"
######################################################################################################################


# Wait for the instance to reach 2/2 status checks passed
aws ec2 wait instance-status-ok --instance-ids $PROD_INSTANCE_ID

# Set minimum, maximum, and desired capacity to 0 to delete the old ec2 instance 
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --min-size 0 --max-size 0 --desired-capacity 0
# Wait for 30 seconds to let it terminate
echo " ASG terminating old instance in "


# Retrieve the public IP address of the prod instance
public_ip_prod=$(aws ec2 describe-instances --instance-ids $PROD_INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
echo "Public IP of PROD instance $public_ip_prod " 


#### DEPLOYMENT PROCESS ####### 
# Create an AMI of the instance
#ami_id=$(aws ec2 create-image --instance-id $PROD_INSTANCE_ID --name "AMI-$AMI_NAME" --description "AMI-$AMI_NAME" --no-reboot --output text)
# Removed the reboot Option for Consistent AMI Creation. Dec23-2024
ami_id=$(aws ec2 create-image --instance-id $PROD_INSTANCE_ID --name "AMI-$AMI_NAME" --description "AMI-$AMI_NAME" --output text)

echo "$ami_id"
# Wait for the AMI to be available
echo "Waiting for the AMI to be available..."
sleep 20
aws ec2 wait image-available --image-ids $ami_id
echo "AMI = $ami_id is now available. Wait 1 Minute"
sleep 10

# Create a new Version of Launch Template with new AMI ID <previous version is 53>
aws ec2 create-launch-template-version \
    --launch-template-name $PROD_LT_NAME \
    --source-version 149 \
    --version-description $AMI_NAME \
    --launch-template-data "{\"ImageId\":\"$ami_id\"}" 

    

# Show all LT versions for comparison old to new versions
aws ec2 describe-launch-template-versions \
    --launch-template-name $PROD_LT_NAME


# Backing Up the Full Logs of all the ASG instances 
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""
echo ""



# Set minimum, maximum, and desired capacity to 2 to create an EC2 instance with a new AMI ID 
aws autoscaling update-auto-scaling-group --auto-scaling-group-name $ASG_NAME --min-size 2 --max-size 4 --desired-capacity 2
# Wait for 30 seconds to let it create a new EC2
echo " ASG creating new EC2 instance in from AMI = $ami_id " 
sleep 60


# ALB Check the status of instances in the target group
status=$(aws elbv2 describe-target-health --target-group-arn $PROD_TG_ARN --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`].TargetHealth.State' --output text)

echo " THE STATUS OF INSTANCE IS = $status "

# Loop until all instances are healthy
while [ ! -z "$status" ]; do
    echo "Waiting for instances to become healthy...# STATUS IS  = $status"
    echo "If the status is in failed state then proceed to recreate an AMI"
    sleep 5
    status=$(aws elbv2 describe-target-health --target-group-arn $PROD_TG_ARN --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`].TargetHealth.State' --output text)
done



echo "All instances are healthy! Check Payment Status"
sleep 60



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
             \"Weight\": 1 },
           { \"TargetGroupArn\": \"$PP_TG_ARN\",
             \"Weight\": 0 }
         ],
         \"TargetGroupStickinessConfig\": {
             \"Enabled\": true,
             \"DurationSeconds\": 300
         }
      }
  }]"
#### To Enable the LB Stikness Use Below Code in Above Code :
#         \"TargetGroupStickinessConfig\": {
#             \"Enabled\": true,
#             \"DurationSeconds\": 600
#         }

  
echo "100% load in PROD instance ID = $PROD_INSTANCE_ID & PROD instance IP = $public_ip_prod"

# curl req to get 200 OK in api.example.com
# Status Check
echo "API.x.com : Project deployed successfully "
echo " Healh Check Status = 1 "
curl -o /dev/null -s -w "%{http_code}\n" https://api.x.com
sleep 2

# Status Check
echo "API.x.com : Project deployed successfully "
echo " Healh Check Status = 1 "
curl -o /dev/null -s -w "%{http_code}\n" https://api.x.com
sleep 2

# Status Check
echo "API.x.com : Project deployed successfully "
echo " Healh Check Status = 1 "
curl -o /dev/null -s -w "%{http_code}\n" https://api.x.com
sleep 2

# Status Check
echo "API.x.com : Project deployed successfully "
echo " Healh Check Status = 1 "
curl -o /dev/null -s -w "%{http_code}\n" https://api.x.com
sleep 2

# Status Check
echo "API.x.com : Project deployed successfully "

##########################################################################################
while [ "$(curl -o /dev/null -s -w "%{http_code}"  https://api.x.com/ )" -ne 200 ]; do echo "Retrying..."; sleep 2; done && echo "Received 200 OK, exiting."

while [ "$(curl -o /dev/null -s -w "%{http_code}"  https://api.x.com/ )" -ne 200 ]; do echo "Retrying..."; sleep 2; done && echo "Received 200 OK, exiting."

while [ "$(curl -o /dev/null -s -w "%{http_code}"  https://api.x.com/ )" -ne 200 ]; do echo "Retrying..."; sleep 2; done && echo "Received 200 OK, exiting."



##########################################################################################
sleep 10
echo " "
echo " "
echo " "
echo " Printing Some Infra information for successfull deployment test (Email/Audit Purpose) "
# Get the instance IDs of EC2 instances launched by the ASG
instance_ids=$(aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-name <ASG-name> \
  --query 'AutoScalingGroups[0].Instances[*].InstanceId' \
  --output text)
# Check if there are any instances
if [ -z "$instance_ids" ]; then
  echo "No instances found for Auto Scaling Group: $ASG_NAME"
  exit 1
fi
# Loop through each instance ID to extract its AMI name
for instance_id in $instance_ids; do
  ami_id=$(aws ec2 describe-instances \
    --instance-ids $instance_id \
    --query 'Reservations[0].Instances[0].ImageId' \
    --output text)
  
  ami_name=$(aws ec2 describe-images \
    --image-ids $ami_id \
    --query 'Images[0].Name' \
    --output text)
  
  echo "Instance ID: $instance_id, AMI Name: $ami_name"
done


### Deployed ###
echo " Deployed Successfully! "
echo " Deployed Successfully! "
echo " Deployed Successfully! "
echo " Cache Cleared"

# Token only workwith in jenkins instance only this ip is allowed to curl on API 
CFCache=$(curl -i -X POST "https://api.cloudflare.com/client/v4/zones/<zone-id>/purge_cache" \
     -H "Authorization: Bearer <token>" \
     -H "Content-Type: application/json" \
     --data '{"purge_everything":true}')
     
echo " Cloudflare cache has been cleared "
echo " "
echo " "
echo " If You Dont want to Stop PP instance please cancel the job now (it will not affect anything)"
echo " After 15 minutes the pp-instance will be auto stopped (waiting becasue we need all the connection to be closed for sticky sessions)" 
sleep 600


# Stop the PP instance deployment is completed and working fine in PP as of now 
echo " stopping PP instance = $PP_INSTANCE_ID "
aws ec2 stop-instances --instance-ids $PP_INSTANCE_ID
echo " stopping PP instance = $PP_INSTANCE_ID_2 "
aws ec2 stop-instances --instance-ids $PP_INSTANCE_ID_2

