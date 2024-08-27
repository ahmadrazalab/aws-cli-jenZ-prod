# EC2 Connection for deployment setup
export EC2_USER=root
export INSTANCE_ID="i-xxxxxxxxxxxxx"
export AWS_DEFAULT_REGION=xxxxxxxxxxxxx


########## Deployment started in PP SERVER ###############

# Start the instance
aws ec2 start-instances --instance-ids $INSTANCE_ID

# Wait for the instance to reach 2/2 status checks passed
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID

# Retrieve the public IP address of the PP instance
public_ip=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
echo "PROD Public IP =  $public_ip "

# CODE DEPLOYMENT PROCESS : 
# zipping the code and trasnfering to server 
tar -cf api.tar.gz .
scp -o StrictHostKeyChecking=no -P 33000 $EC2_USER@$public_ip:/var/www/backend/

# SSH into the PP EC2 instance and execute commands
ssh -o StrictHostKeyChecking=no -p 33000 $EC2_USER@$public_ip << EOF
  echo "unzip and deploy"
  cd /var/www/backend/
  tar xvf api.tar.gz

  service nginx restart
EOF


echo "Code Successfully Deployed in PP Server"
