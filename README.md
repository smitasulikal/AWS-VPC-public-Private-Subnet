Terraform: AWS VPC with Private and Public Subnets

1)Once you’ve defined the environment configuration files, it’s time to bring it up. You can do that by firing off:

terraform apply

2)That’ll bring up the VPC, all of the security groups, the NAT instance , Web server instance and DB instances.
set of machines IPs:

Instance Name	    Private IP	   Public IP
============================================

VPC NAT	          10.0.0.210	   52.16.161.59

Web Server 1    	10.0.0.37	     52.16.185.18

DB Server 1	      10.0.1.22 	   n/a

(Obviously, with different values).


3)Connect to the NAT instance:

ssh -i ~/.ssh/key_name.pem -A ec2-user@52.16.161.59


4)And then inside the NAT instance, we be able to connect to either of the other two instances i.e web server or DB server :

# Web Server 1
ssh ec2-user@10.0.0.37

# DB Server 1
ssh ec2-user@10.0.1.22
