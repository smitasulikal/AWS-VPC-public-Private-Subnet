provider "aws" {
}

/*VPC*/
resource "aws_vpc" "vpc" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

/*internet gateway */
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-igw"
    Environment = var.environment
  }
}

/*eip ip */
resource "aws_eip" "nat_eip" {
  vpc = true
  depends_on                = [aws_internet_gateway.gw]
}

/* NAT gateway */
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id
  depends_on = [aws_internet_gateway.gw]
  tags = {
    Name        = "natgw"
    Environment = var.environment
  }
}

/*public subnet */
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.public_subnet_cidr
  availability_zone = var.az
}

/*private subnet */
resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_subnet_cidr
  availability_zone = var.az
}

/* Routing table for private  NAT GW */
resource "aws_route" "private_nat_gateway" {
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  instance_id      = aws_instance.nat-instance.id
}

/* Routing table for private subnet */
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "${var.environment}-private-route-table"
    Environment = var.environment
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  route {

      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.gw.id
    }
  tags = {
    Name        = "${var.environment}-public-route-table"
    Environment = var.environment
  }
}


/* Route table associations  for public and private subnet with route table*/
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

/*==== NAT Security Group ======*/
resource "aws_security_group" "nat" {
  name        = "${var.environment}-NAT-sg"
  description = "NAT security group for NAT instance"
  
  vpc_id      = aws_vpc.vpc.id
  depends_on  = [aws_vpc.vpc]
  ingress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port = "443"
    to_port   = "443"
    protocol  = "tcp"
    cidr_blocks = ["10.0.1.0/24"]
  }

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = "-1"
    to_port   = "-1"
    protocol  = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "80"
    to_port   = "80"
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "443"
    to_port   = "443"
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "-1"
    to_port   = "-1"
    protocol  = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = "22"
    to_port   = "22"
    protocol  = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Environment = "${var.environment}-NAT-SecGrp"
  }
}

/*==== NAT instance ======*/
resource aws_instance "nat-instance" {
  ami           = var.ami-id
  instance_type = var.instanceType
  availability_zone = var.az
  key_name = "22key"
  vpc_security_group_ids = [aws_security_group.nat.id]
  subnet_id      = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  source_dest_check = false

  provisioner "local-exec" {
    command = "echo ${aws_instance.nat-instance.public_ip} >> nat_public_ips.txt"
  }

  tags = {
    Name = "${var.environment}-NATInstance"
  }
}

/*==== NAT EIP ======*/
resource "aws_eip" "nat" {
  vpc = true
  instance      = aws_instance.nat-instance.id
}


/*====================================================*/
/*
Web Server  in public subnet
*/
/*====================================================*/

resource "aws_security_group" "web" {
    name = "vpc_web"
    description = "Allow incoming HTTP connections."

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress { # SQL Server
        from_port = 1433
        to_port = 1433
        protocol = "tcp"
        cidr_blocks = ["10.0.1.0/24"]
    }
    egress { # MySQL
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        cidr_blocks = ["10.0.1.0/24"]
    }
    /*allowing any connection initiation to the outside world */
    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "${var.environment}-WebServerSecGrp"
    }
}

/*
  Web Server   public instance
*/
resource "aws_instance" "web-1" {
    ami = var.ami-id
    availability_zone = var.az
    instance_type = var.instanceType
    key_name = "22key"
    vpc_security_group_ids = [aws_security_group.web.id]
    subnet_id      = aws_subnet.public_subnet.id
    associate_public_ip_address = true
  #source_dest_check = false

    provisioner "local-exec" {
      command = "echo ${aws_instance.web-1.public_ip} >> Web_public_ips.txt"
    }

    provisioner "remote-exec" {
      inline = [
        #"sudo yum install epel-release",
        "sudo amazon-linux-extras install epel -y",
        #"sudo yum install nginx -y",
        "sudo amazon-linux-extras install nginx1 -y",
        "sudo systemctl start nginx",
        /*"sudo firewall-cmd --permanent --zone=public --add-service=http",
        "sudo firewall-cmd --permanent --zone=public --add-service=https",
        "sudo firewall-cmd --reload"
        */
      ]
    }

    connection {
       type = "ssh"
       user = "ec2-user"
       private_key = file("./22key.pem")
       /*Make sure to have the ec2-key.pem file present in the working
       directory for the provisioner to be able to connect to the instance.*/
       #private_key = file("22key.pem")
       host = self.public_ip
     }

    tags = {
        Name = "${var.environment}-WebServer1Instances"
    }
}

resource "aws_eip" "web-1" {
  instance      = aws_instance.web-1.id
  vpc = true
}



/*====================================================*/
/*
  Database Servers in private subnet
*/
/*====================================================*/


resource aws_security_group "db" {
  name = "vpc_db"
  description = "allow incoming DB connections"

  ingress {  # SQL Server
       from_port = 1433
       to_port = 1433
       protocol = "tcp"
       security_groups = [aws_security_group.web.id]
  }

  ingress {  # MySQL Server
         from_port = 3306
         to_port = 3306
         protocol = "tcp"
        security_groups = [aws_security_group.web.id]
  }

  ingress {
      from_port = 22
      to_port = 22
      protocol = "tcp"
      cidr_blocks = [var.vpc_cidr]
  }

  ingress {
      from_port = -1
      to_port = -1
      protocol = "icmp"
      cidr_blocks = [var.vpc_cidr]
  }


    egress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = aws_vpc.vpc.id

    tags = {
       Name = "DBServerSG"
   }
}

resource aws_instance "db-1" {
  ami = var.ami-id
  availability_zone = var.az
  instance_type = var.instanceType
  key_name = "22key"
  vpc_security_group_ids = [aws_security_group.db.id]
  subnet_id      = aws_subnet.private_subnet.id
  source_dest_check = false

  provisioner "local-exec" {
    command = "echo ${aws_instance.db-1.private_ip} >> DB_private_ips.txt"
  }
  tags = {
      Name = "${var.environment}-DBServer1"
  }
}
