#!/bin/bash -ex  
touch /home/ec2-user/value.txt
chmod 777 /home/ec2-user/value.txt
sudo bash
yum update -y
sudo curl -s https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/maven.sh | bash -ex
sudo yum install Xvfb -y
sudo yum install docker -y
cd /home/ec2-user
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/pmd-bin-5.4.1.zip
unzip -q pmd-bin-5.4.1.zip
wget https://s3-us-west-2.amazonaws.com/cicdpoc/jdk-8u60-linux-x64.rpm
yum localinstall jdk-8u60-linux-x64.rpm -y
chmod a+rwx /etc/profile
echo \export JAVA_HOME=/home/ec2-user\ >> /etc/profile
echo \export PATH=$PATH:/usr/lib/jvm/jre/bin\ >> /etc/profile
source /etc/profile
sudo yum install git -y
cd /home/ec2-user
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/dbunit-2.4.9.jar
jar -xf /home/ec2-user/dbunit-2.4.9.jar
mkdir jMeter
cd jMeter
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/apache-jmeter-5.1.1.tgz
tar -xzvf apache-jmeter-5.1.1.tgz
cd apache-jmeter-5.1.1/bin
chmod 777 jmeter.sh
sudo yum install java-1.8.0 -y
wget -O /usr/lib/jenkins.war https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/jenkins.war
java -Djenkins.install.runSetupWizard=false -jar /usr/lib/jenkins.war &>/dev/null &
sleep 1m
sudo curl -s https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/firefox.sh | bash -ex
PRIVATE_IP=`curl -s http://169.254.169.254/latest/meta-data/local-ipv4`
cp /root/.jenkins/war/WEB-INF/jenkins-cli.jar /tmp/jenkins-cli.jar
chmod a+rwx /tmp/jenkins-cli.jar
cd /root/.jenkins/
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/jenkinsbackupXML.zip
unzip -o jenkinsbackupXML.zip
sleep 10
rm -rf org.jenkinsci.plugins.rundeck.RundeckNotifier.xml
rm -rf quality.gates.jenkins.plugin.GlobalConfig.xml
rm -rf hudson.plugins.sonar.SonarGlobalConfiguration.xml
rm -rf jenkins.model.JenkinsLocationConfiguration.xml
rm -rf credentials.xml
rm -rf plugins/ users/
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/quality.gates.jenkins.plugin.GlobalConfig.xml
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/hudson.plugins.sonar.SonarGlobalConfiguration.xml
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/jenkins.model.JenkinsLocationConfiguration.xml
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/org.jenkinsci.plugins.rundeck.RundeckNotifier.xml
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/credentials.xml
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/Petclinic-liquibase/plugins.zip
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/users.zip
unzip -o users.zip
unzip -o plugins.zip
rm -rf *.zip
cd /root/.jenkins/jobs/
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/Petclinic.zip
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/Petclinic-liquibase/Petclinic-liquibase.zip
unzip -o Petclinic.zip
unzip -o Petclinic-liquibase.zip
rm -rf Petclinic.zip Petclinic-liquibase.zip

cd /root/.jenkins/jobs/Petclinic
rm -rf config.xml
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/Petclinic/config.xml
cd /root/.jenkins/jobs/Petclinic-liquibase
rm -rf config.xml
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/Petclinic-liquibase/config.xml

wget https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm
md5sum mysql57-community-release-el7-9.noarch.rpm
sudo rpm -ivh mysql57-community-release-el7-9.noarch.rpm
sudo yum install mysql-server -y

cd /home/ec2-user
mkdir sql-init
cd sql-init
wget https://labassets.s3-us-west-2.amazonaws.com/Dependencies/Jenkins/Job-updated/Petclinic-liquibase/initDB-Petclinic-Liquibase.sql
sudo systemctl start mysqld

sleep 10
var=`grep 'temporary password' /var/log/mysqld.log | awk -F': ' '{print $NF}'`
mysqladmin -u root --password=$var password Mysql@123456
mysql -u root -pMysql@123456 < /home/ec2-user/sql-init/initDB-Petclinic-Liquibase.sql

sudo service docker start
java -jar /tmp/jenkins-cli.jar -s http://$PRIVATE_IP:8080/ safe-restart
sed -i '133i <server><id>nexus-snapshots</id><username>deployment</username><password>deployment123</password></server>' /usr/share/apache-maven/conf/settings.xml