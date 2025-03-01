# EC2 Connection for deployment setup
export EC2_USER=root
export INSTANCE_ID="i-x"
export INSTANCE_ID2="i-x"

export AWS_DEFAULT_REGION=ap-south-1


########## Deployment started in PP SERVER ###############

# Start the instance
aws ec2 start-instances --instance-ids $INSTANCE_ID
aws ec2 start-instances --instance-ids $INSTANCE_ID2

# Wait for the instance to reach 2/2 status checks passed
aws ec2 wait instance-status-ok --instance-ids $INSTANCE_ID

# Retrieve the public IP address of the PP instance
public_ip=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
echo "PROD Public IP =  $public_ip "

# CODE DEPLOYMENT PROCESS : 
# zipping the code and trasnfering to server 
#cp /var/lib/jenkins/workspace/config/backend/.env .
aws secretsmanager get-secret-value --secret-id backend-api --query SecretString --output text | jq -r 'to_entries|map("\(.key)=\(.value)")|.[]' > .env
tar -cvf api.tar .
cat composer.json | grep dagar
scp -o StrictHostKeyChecking=no -P 33333 ./api.tar $EC2_USER@$public_ip:/var/www/backend/

# SSH into the PP EC2 instance and execute commands
ssh -o StrictHostKeyChecking=no -p 33333 $EC2_USER@$public_ip << EOF
  set -e
  echo "unzip and deploy"
  cd /var/www/backend/
  tar -xvf api.tar --overwrite
  ls -la
  rm -rf api.tar
  rm -rf ./vendor ./composer.lock
  COMPOSER_ALLOW_SUPERUSER=1 composer install --prefer-dist --no-dev -o --no-interaction
  php artisan cache:clear
  php artisan route:clear
  php artisan config:clear
  php artisan view:clear
  php artisan event:clear
  php artisan view:cache
  php artisan route:cache
  chown -R www-data: ./
  chmod -R 777 ./storage
  ls -la
  git branch 
  service nginx restart
  systemctl restart php8.2-fpm
EOF

echo "Code Successfully Deployed in PP (1) Server"




