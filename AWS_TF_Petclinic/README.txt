Changes made in the TF Scripts: 


Rundeck was not working before, not working after adding Role, Policy and Instance Profile.
Jenkins-Linux tested - working
Jenkins-Windows testing - pending

Changed jenkins.sh such that Selvan's Git credentials are replaced by DevOps0110 account credentials.

Added comments describing the tools installed in vpc.tf

Rundeck policy changed to access EBS,S3,EC2 -> Thus, no need to  add credentials in job.xml