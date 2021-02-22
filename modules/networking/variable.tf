variable "region" {
  description = "this is the default region"
  default     = "ap-south-1"
}

/*ami-id for amazon linux in ap-south-1 region */
variable "ami-id" {
  default = "ami-08e0ca9924195beba"
}
variable "instanceType" {
  default = "t2.micro"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  #default = ["10.0.1.0/24,10.0.2.0/24","10.0.3.0/24"]
  default = "10.0.0.0/24"
}

variable "az" {
  type = string
  #default = ["ap-south-1a","ap-south-1b","ap-south-1c "]
  default = "ap-south-1a"
}

variable "private_subnet_cidr" {
  #default = ["10.0.1.0/24,10.0.5.0/24","10.0.6.0/24"]
  default = "10.0.1.0/24"
}

variable "environment" {
  default = "EXvpc"
}
