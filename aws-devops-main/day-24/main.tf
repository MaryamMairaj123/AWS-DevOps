resource "aws_vpc" "myvpc" {
 cidr_block = var.cidr 

tags = {
    Name = "Terraform-VPC"
  }
}
# map_public_ip_on_launch - (Optional) Specify true to indicate that instances 
# launched into the subnet should be assigned a public IP address. Default is false.
resource "aws_subnet" "sub1" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.0.0/24"
    availability_zone = "us-west-1a"
    map_public_ip_on_launch = true
tags = {
    Name = "Terraform-Subnet1"
  }
}

resource "aws_subnet" "sub2" {
    vpc_id = aws_vpc.myvpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-west-1b"
    map_public_ip_on_launch = true
tags = {
    Name = "Terraform-subnet2"
  }
}

# only igw will not give the access of subnet, for access we need to create route tables 
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.myvpc.id
tags = {
    Name = "Terraform-IGW"
  }
}

# route tables defines where should be the traffic go to 
resource "aws_route_table" "RT" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "Terraform-RT"
  }
}
# connect route table with the subnet 
resource "aws_route_table_association" "rta1" {
    subnet_id = aws_subnet.sub1.id
    route_table_id = aws_route_table.RT.id
}

resource "aws_route_table_association" "rta2" {
    subnet_id = aws_subnet.sub2.id
    route_table_id = aws_route_table.RT.id
}

#create security groups
resource "aws_security_group" "SG" {
  name        = "mysg"
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "mysg"
  }
  ingress {
    description = "HTTP from VPC"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH from VPC"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "mys3bucket" {
    bucket = "maryam-s3-bucket-project"
    
    tags = {
    Name = "Terraform-S3-bucket"
  }
}

resource "aws_s3_bucket_ownership_controls" "s3ownership" {
  bucket = aws_s3_bucket.mys3bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}
resource "aws_s3_bucket_public_access_block" "s3public" {
  bucket = aws_s3_bucket.mys3bucket.id
  
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
resource "aws_s3_bucket_acl" "s3-acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.s3ownership,
    aws_s3_bucket_public_access_block.s3public,
  ]

  bucket = aws_s3_bucket.mys3bucket.id
  acl    = "public-read"
}

# Upload terraform.png to the S3 bucket using the updated aws_s3_object resource
resource "aws_s3_object" "terraform_image" {
  bucket = aws_s3_bucket.mys3bucket.id
  key    = "images/terraform.png"   # This is the S3 object key
  source = "terraform.png"  # Path to your image in the project directory
  acl    = "public-read"  # Depending on the use case
}


# Create an instance profile for the EC2 role
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2_instance_profile"
  role = aws_iam_role.ec2_role.name
}
# create an ec2 instance
resource "aws_instance" "Terraformwebserver1" {
    ami = "ami-0da424eb883458071"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.SG.id ]
    subnet_id = aws_subnet.sub1.id
    user_data = base64encode(file("user_data.sh"))
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
    
    tags = {
    Name = "Terraformwebserver1"
  }
}

resource "aws_instance" "Terraformwebserver2" {
    ami = "ami-0da424eb883458071"
    instance_type = "t2.micro"
    vpc_security_group_ids = [ aws_security_group.SG.id ]
    subnet_id = aws_subnet.sub2.id
    user_data = base64encode(file("user_data1.sh"))
    iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

    
    tags = {
    Name = "Terraformwebserver2"
  }
}

resource "aws_iam_role" "ec2_role" {
  name = "ec2_role"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }]
  })
}

resource "aws_iam_policy" "ec2_s3_policy" {
  name   = "ec2_s3_policy"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [{
      "Action": [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket"
      ],
      "Effect": "Allow",

      "Resource": [
        "arn:aws:s3:::maryam-s3-bucket-project/*",
        "arn:aws:s3:::maryam-s3-bucket-project"
      ]

    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_attach_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_s3_policy.arn
}

#create alb
resource "aws_lb" "myALB" {
  name = "myALB"
  internal = false
  load_balancer_type = "application"

  security_groups = [aws_security_group.SG.id]
  subnets = [ aws_subnet.sub1.id, aws_subnet.sub2.id ]

  tags = {
    Name = "Target-ALB" 
  }
}

resource "aws_lb_target_group" "albtarget" {
  name = "myTG"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.myvpc.id

  health_check {
    path = "/"
    port = "traffic-port"

  }
}

resource "aws_lb_target_group_attachment" "albattachment1" {
  target_group_arn = aws_lb_target_group.albtarget.arn 
  target_id = aws_instance.Terraformwebserver1.id
  port = 80
}

resource "aws_lb_target_group_attachment" "albattachment2" {
  target_group_arn = aws_lb_target_group.albtarget.arn
  target_id = aws_instance.Terraformwebserver2.id
  port = 80
}

resource "aws_lb_listener" "listenerlb" {
  load_balancer_arn = aws_lb.myALB.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.albtarget.arn
    type = "forward"
  }
}

output "loadbalancerdns" {
  value = aws_lb.myALB.dns_name
}

output "instance_public_ip1" {
  value = aws_instance.Terraformwebserver1.public_ip
}

output "instance_public_ip2" {
  value = aws_instance.Terraformwebserver2.public_ip
}
output "s3_image_url" {
  value = aws_s3_bucket.mys3bucket.bucket_domain_name
}
