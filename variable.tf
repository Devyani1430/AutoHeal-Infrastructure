variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public-cidr1" {
  default = "10.0.1.0/20"
}


# For Public Subnet 1
variable "AZ1" {
  default = "us-east-1a"
}

variable "public-cidr2" {
  default = "10.0.16.0/20"
}

# For Public Subnet 2
variable "AZ2" {
  default = "us-east-1c"
}

variable "IGW-cidr" {
  default = "0.0.0.0/0"
}