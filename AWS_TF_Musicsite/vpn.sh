#!/bin/bash -ex 
touch /home/ec2-user/value.txt 
chmod 777 /home/ec2-user/value.txt 
sudo bash
sudo curl -s https://labassets.s3-us-west-2.amazonaws.com/Dependencies/OpenVPN/VPN.sh | bash -ex