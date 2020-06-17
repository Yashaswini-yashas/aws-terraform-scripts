#!/bin/bash -ex
touch /home/ec2-user/value.txt
chmod 777 /home/ec2-user/value.txt
sudo yum install dos2unix -y
PRIVATE_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
wget -O sonarUserDataPrivate_v6.5.sh https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Nexus/sonarUserDataPrivate_v6.5_WebhookConfig.sh | bash
sudo chmod 777 sonarUserDataPrivate_v6.5.sh
sudo dos2unix sonarUserDataPrivate_v6.5.sh
sudo ./sonarUserDataPrivate_v6.5.sh
