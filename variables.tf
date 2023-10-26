variable "region" {
  default = "ap-southeast-2"
}

variable "ami" {
  type = map(string)
  default = {
    master = "ami-0d02292614a3b0df1"
    worker = "ami-0d02292614a3b0df1"
  }
}

variable "instance_type" {
  default = {
    master = "t2.medium"
    worker = "t2.micro"
  }
}

variable "worker_instance_count" {
  type = number
  default = 2
}