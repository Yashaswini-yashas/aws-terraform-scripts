/*
  VPC
*/
resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = {
        Name = "terraform-aws-vpc"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
}

/*
  NAT Instance configuration
*/
resource "aws_security_group" "nat" {
    name = "sg_nat"
    description = "Allow traffic to pass from the private subnet to the internet"

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["${var.private_subnet_cidr}"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = -1
        to_port = -1
        protocol = "icmp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    vpc_id = "${aws_vpc.default.id}"

    tags = {
        Name = "NATSG"
    }
}

resource "aws_instance" "nat" {
    ami = "ami-69ae8259"    # this is a special ami preconfigured to do NAT
    availability_zone = "us-west-2a"
    instance_type = "t2.micro"
    key_name = "Prathamesh_Oregon"
    vpc_security_group_ids = ["${aws_security_group.nat.id}"]
    subnet_id = "${aws_subnet.us-west-2-public.id}"
    associate_public_ip_address = true
    source_dest_check = false

    tags = {
        Name = "Lab_NAT_Instance",
        Tools-installed = "NAT"
    }
}

resource "aws_eip" "nat" {
    instance = "${aws_instance.nat.id}"
    vpc = true
     tags = {
        Name = "Lab_terraform_NAT"
    }
}

/*
  Public Subnet
*/
resource "aws_subnet" "us-west-2-public" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.public_subnet_cidr}"
    availability_zone = "us-west-2a"
    map_public_ip_on_launch = true
    tags = {
        Name = "Public Subnet"
    }
}

resource "aws_route_table" "us-west-2-public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags = {
        Name = "Public Subnet"
    }
}

resource "aws_route_table_association" "us-west-2-public" {
    subnet_id = "${aws_subnet.us-west-2-public.id}"
    route_table_id = "${aws_route_table.us-west-2-public.id}"
}

/*
  Private Subnet
*/
resource "aws_subnet" "us-west-2-private" {
    vpc_id = "${aws_vpc.default.id}"

    cidr_block = "${var.private_subnet_cidr}"
    availability_zone = "us-west-2a"

    tags = {
        Name = "Private Subnet"
    }
}

resource "aws_route_table" "us-west-2-private" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        instance_id = "${aws_instance.nat.id}"
    }

    tags = {
        Name = "Private Subnet"
    }
}

resource "aws_route_table_association" "us-west-2-private" {
    subnet_id = "${aws_subnet.us-west-2-private.id}"
    route_table_id = "${aws_route_table.us-west-2-private.id}"
}

/*
  VPN Instance configuration
*/
resource "aws_security_group" "vpn" {
    name = "sg_vpn"
    description = "Allow traffic to pass from the private subnet to the internet"
    ingress {
        from_port = 1194
        to_port = 1194
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags = {
        Name = "VPNSG"
    }
}

resource "aws_instance" "vpn" {
    ami = "ami-079f731edfe27c29c" # ami use to configure vpn
    availability_zone = "us-west-2a"
    instance_type = "t2.medium"
    key_name = "Prathamesh_Oregon"
    vpc_security_group_ids = ["${aws_security_group.vpn.id}"]
    subnet_id = "${aws_subnet.us-west-2-public.id}"  
    associate_public_ip_address = true
    source_dest_check = true
	user_data = "${file("vpn.sh")}"
    tags = {
        Name = "Lab_VPN_Instance"
    }
}

resource "aws_eip" "vpn" {
    instance = "${aws_instance.vpn.id}"
    vpc = true
     tags = {
        Name = "Lab_terraform_VPN"
    }
}

/*
  Jenkins Instance configuration
*/
resource "aws_security_group" "jenkins" {
    name = "sg_jenkins_Linux"
    description = "Allow traffic to pass from the private subnet to the internet"
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	 ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags = {
        Name = "JenkinsSG"
    }
	depends_on = [aws_instance.nat]
}

resource "aws_network_interface" "jenkins" {
  subnet_id = "${aws_subnet.us-west-2-private.id}"
  private_ips = ["10.0.2.17"]
  security_groups = ["${aws_security_group.jenkins.id}"]
  tags = {
    Name = "Jenkins_network_interface"
  }
  depends_on = [aws_instance.nat]
}

resource "aws_instance" "jenkins" {
    ami = "ami-04590e7389a6e577c"
    availability_zone = "us-west-2a"
    instance_type = "m3.medium"
    key_name = "Prathamesh_Oregon"
	user_data = "${file("jenkins.sh")}"
	network_interface {
    network_interface_id = "${aws_network_interface.jenkins.id}"
    device_index         = 0
	}
    tags = {
        Name = "Lab_Jenkins_Instance",
        Tools-installed = "Jenkins"
    }
	depends_on = [aws_instance.nat]
}

/*
  Sonar_and_Nexus Instance configuration
*/
resource "aws_security_group" "sonarandnexus" {
    name = "sg_sonarandnexus"
    description = "Allow traffic to pass from the private subnet to the internet"
    ingress {
        from_port = 9000
        to_port = 9000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	ingress {
        from_port = 8081
        to_port = 8081
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	 ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags = {
        Name = "SonarandNexusSG"
    }
	depends_on = [aws_instance.nat]
}

resource "aws_network_interface" "sonarandnexus" {
  subnet_id = "${aws_subnet.us-west-2-private.id}"
  private_ips = ["10.0.2.18"]
  security_groups = ["${aws_security_group.sonarandnexus.id}"]
  tags = {
    Name = "SonarandNexus_network_interface"
  }
  depends_on = [aws_instance.nat]
}

resource "aws_instance" "sonarandnexus" {
    ami = "ami-c229c0a2"
    availability_zone = "us-west-2a"
    instance_type = "t2.medium"
    key_name = "Prathamesh_Oregon"
	user_data = "${file("sonarandnexus.sh")}"
	network_interface {
    network_interface_id = "${aws_network_interface.sonarandnexus.id}"
    device_index         = 0
	}
	
    tags = {
        Name = "Lab_SonarandNexus_Instance",
        Tools-installed = "Sonar and Nexus"
    }
	depends_on = [aws_instance.nat]
}

/*
  Rundeck Instance configuration
*/
resource "aws_security_group" "rundeck" {
    name = "sg_rundeck"
    description = "Allow traffic to pass from the private subnet to the internet"
    ingress {
        from_port = 4440
        to_port = 4440
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	 ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
	ingress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    vpc_id = "${aws_vpc.default.id}"

    tags = {
        Name = "RundeckSG"
    }
	depends_on = [aws_instance.nat]
}

resource "aws_network_interface" "rundeck" {
  subnet_id = "${aws_subnet.us-west-2-private.id}"
  private_ips = ["10.0.2.19"]
  security_groups = ["${aws_security_group.rundeck.id}"]
  tags = {
    Name = "Rundeck_network_interface"
  }
  depends_on = [aws_instance.nat]
}

resource "aws_iam_role" "AmazonS3FullAccessRole" {
    name = "AmazonS3FullAccessRole"
    assume_role_policy = "${file("IAMRole.json")}"
}

resource "aws_iam_role_policy" "policy" {
  name        = "S3FullAccessPolicy"
  role = "${aws_iam_role.AmazonS3FullAccessRole.name}"
  policy = "${file("AmazonS3FullAccessPolicy.json")}"
}

resource "aws_iam_instance_profile" "instanceProfile" {
    name = "Profile"
    role = "${aws_iam_role.AmazonS3FullAccessRole.name}"
    depends_on = [aws_iam_role.AmazonS3FullAccessRole]
}

resource "aws_instance" "rundeck" {
    ami = "ami-04590e7389a6e577c"
    iam_instance_profile = "${aws_iam_instance_profile.instanceProfile.name}"
    availability_zone = "us-west-2a"
    instance_type = "t2.medium"
    key_name = "Prathamesh_Oregon"
	user_data = "${file("rundeck.sh")}"
	network_interface {
    network_interface_id = "${aws_network_interface.rundeck.id}"
    device_index         = 0
	}
	
    tags = {
        Name = "Lab_Rundeck_Instance",
        Tools-installed = "Rundeck"
    }
	depends_on = [aws_instance.nat,
                  aws_iam_instance_profile.instanceProfile]

}