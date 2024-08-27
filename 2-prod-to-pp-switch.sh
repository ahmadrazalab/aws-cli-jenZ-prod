export AWS_DEFAULT_REGION=xxxxxxxxxxxxx
# NOTE : Traffic Switch from PROD to PP only (3 Steps )


# Replace YOUR_TARGET_GROUP_ARN with the ARN of your target group
export ALB_LISTENER_ARN=arn:aws:elasticloadbalancing:ap-south-1:xxxxxxxxxxxxx:listener/app/JENZ/xxxxxxxxxxxxx/xxxxxxxxxxxxx
# MPTG-TG-1
export PP_TG_ARN="arn:aws:elasticloadbalancing:ap-south-1:xxxxxxxxxxxxx:targetgroup/PP-TG-1/xxxxxxxxxxxxx"
# MPTG-TG
export PROD_TG_ARN="arn:aws:elasticloadbalancing:ap-south-1:xxxxxxxxxxxxx:targetgroup/PROD-TG-2/xxxxxxxxxxxxx"
#####################################################################################################################



# ALB HealthCheck status of instances in the target group of PP for the traffic switch 
status=$(aws elbv2 describe-target-health --target-group-arn $PP_TG_ARN --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`].TargetHealth.State' --output text)
# Loop until all instances are healthy in the PP TG
while [ ! -z "$status" ]; do
    echo "Waiting for instances to become healthy..."
    sleep 5
    status=$(aws elbv2 describe-target-health --target-group-arn $PP_TG_ARN --query 'TargetHealthDescriptions[?TargetHealth.State!=`healthy`].TargetHealth.State' --output text)
done

echo "All instances are healthy! in PP TG"
echo " begin to traffic switch in 3 Seconds "
sleep 3


##### Check for SSL Certificates
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
             \"Weight\": 0 },
           { \"TargetGroupArn\": \"$PP_TG_ARN\",
             \"Weight\": 100 }
         ],
         \"TargetGroupStickinessConfig\": {
             \"Enabled\": true,
             \"DurationSeconds\": 3600
         }
      }
  }]"



echo " 100% traffic is on PP Server wait 5 min to check the payment crash while 100% LOAD on Server " 


