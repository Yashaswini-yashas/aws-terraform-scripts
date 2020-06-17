#!/bin/bash -ex
sudo bash
sudo yum install java-1.8.0-openjdk-devel -y
touch /home/ec2-user/value.txt
chmod 777 /home/ec2-user/value.txt
sudo yum install yum-utils
sudo yum groupinstall development -y
sudo amazon-linux-extras install epel
curl 'https://setup.ius.io/' -o setup-ius.sh
yum install https://repo.ius.io/ius-release-el7.rpm https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y
yum repolist ius
yum install --enablerepo=ius python36u -y
python3.6 -V
sudo yum install python36u-pip -y
sudo yum install python36u-devel -y
cd /home/ec2-user
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Rundeck/rundeck-2.6.4-1.15.GA.noarch.rpm
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Rundeck/rundeck-config-2.6.4-1.15.GA.noarch.rpm
rpm -Uvh rundeck-2.6.4-1.15.GA.noarch.rpm rundeck-config-2.6.4-1.15.GA.noarch.rpm
cd /etc/rundeck
PRIVATE_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
echo $PRIVATE_IP
sed -i "s|localhost|$PRIVATE_IP|g" /etc/rundeck/rundeck-config.properties
sed -i "s|localhost|$PRIVATE_IP|g" /etc/rundeck/framework.properties
/etc/init.d/rundeckd start
sleep 1m
cd /home/ec2-user
sudo curl -s https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Rundeck/firefox.sh  | bash -ex
echo $PRIVATE_IP >> /home/ec2-user/rundeck_ip.txt
aws s3 cp /home/ec2-user/rundeck_ip.txt s3://cicdpoc/ --acl public-read-write
cd /etc/rundeck
/etc/init.d/rundeckd restart
sleep 60
wget -O /tmp/job1.xml https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Rundeck/ShoppingCart_Deployment.xml
wget -O /tmp/job2.xml https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Rundeck/AWS/MusicSite_Deployment.xml
wget -O /tmp/job3.xml https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Rundeck/AWS/Petclinic-liquibase_Deployment.xml
sleep 60
PRIVATE_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
sudo curl -s https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Rundeck/rundeckauto.bash | bash -ex
mkdir environments
cd environments/
python3.6 -m venv my_env
source my_env/bin/activate
pip install awsebcli==3.14.6
eb --version
/etc/init.d/rundeckd restart
                
               