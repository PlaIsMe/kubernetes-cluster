# Create kubernetes-cluster with Kubeadm on AWS using Terraform & Ansible 26/10/2023 by Pla

## Reference
https://www.youtube.com/watch?v=RkuBsRqgvuE

## Set up enviroment
Install terraform binary from: https://developer.hashicorp.com/terraform/downloads<br>
Then add it to system environment

## Create variables.tf
Go to AWS Service AMI Catalog copy yours ami-xxx of Ubuntu Server 20.04 LTS (HVM), SSD Volume Type<br>
![image](https://github.com/PlaIsMe/kubernetes-cluster/assets/97893528/cb8d6602-54b8-46dd-9b78-8970d9e360eb)<br>
Use your default region<br>
![image](https://github.com/PlaIsMe/kubernetes-cluster/assets/97893528/6073c4d6-9231-4d27-9938-7cd0aba816b9)

```
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
```

## Create main.tf
```
resource "aws_instance" "k8s_master" {
    ami = var.ami["master"]
    instance_type = var.instance_type["master"]
    tags = {
        Name = "k8s-master"

    }
}
```

## Create provider.tf
Go to this link and click Provider and copy the code: https://registry.terraform.io/providers/hashicorp/aws/latest, use your default reagion as region

```
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.22.0"
    }
  }
}

provider "aws" {
  region = var.region
  profile = "default"
}
```

## Create keypair.tf
Run the command: ssh-keygen -f k8s<br>
Then in the keypair.tf

```
resource "aws_key_pair" "k8s" {
  key_name   = "k8s"
  public_key = file("k8s.pub")
}
```

Update main.tf

```
key_name = aws_key_pair.k8s.key_name
```

## Create security_groups.tf

```
resource "aws_security_group" "k8s_master" {
  name        = "k8s_master_sg"
  description = "k8s_master Security Group"

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "API Server"
    from_port        = 6443
    to_port          = 6443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "ETCD"
    from_port        = 2379
    to_port          = 2380
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Weavenet TCP"
    from_port        = 6783
    to_port          = 6783
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Weavenet TCP"
    from_port        = 6784
    to_port          = 6784
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Kubelet API, Kube-scheduler, Kube-controller-manager, Read-Only Kubelet API, Kubelet health"
    from_port        = 10248
    to_port          = 10260
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "NodePort Services"
    from_port        = 30000
    to_port          = 32767
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "k8s_master_sg"
  }
}

resource "aws_security_group" "k8s_worker" {
  name        = "k8s_worker_sg"
  description = "k8s_worker Security Group"

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Weavenet TCP"
    from_port        = 6783
    to_port          = 6783
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Weavenet TCP"
    from_port        = 6784
    to_port          = 6784
    protocol         = "udp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Kubelet API, Kube-scheduler, Kube-controller-manager, Read-Only Kubelet API, Kubelet health"
    from_port        = 10248
    to_port          = 10260
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "NodePort Services"
    from_port        = 30000
    to_port          = 32767
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "k8s_worker_sg"
  }
}
```

## Update the main.tf
```
security_groups = ["k8s_master_sg"]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("k8s")
    host        = self.public_ip
  }
  provisioner "file" {
    source      = "./master.sh"
    destination = "/home/ubuntu/master.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/master.sh",
      "sudo sh /home/ubuntu/master.sh k8s-master"
    ]
  }
```

## Update variable.tf
```
variable "worker_instance_count" {
  type = number
  default = 2
}
```

## Update main.tf
```
resource "aws_instance" "k8s_worker" {
  count         = var.worker_instance_count
  ami           = var.ami["master"]
  instance_type = var.instance_type["worker"]
  tags = {
    Name = "k8s-worker-${count.index}"
  }
  key_name        = aws_key_pair.k8s.key_name
  security_groups = ["k8s_worker_sg"]
  depends_on      = [aws_instance.k8s_master]
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("k8s")
    host        = self.public_ip
  }
  provisioner "file" {
    source      = "./worker.sh"
    destination = "/home/ubuntu/worker.sh"
  }
  provisioner "file" {
    source      = "./join-command.sh"
    destination = "/home/ubuntu/join-command.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ubuntu/worker.sh",
      "sudo sh /home/ubuntu/worker.sh k8s-worker-${count.index}"
      "sudo sh /home/ubuntu/join-command.sh"
    ]
  }
}
```

## Create playbook.yaml
```
- hosts: all
  name: fetch join token file
  gather_facts: false
  become: yes
  tasks:
  - name: fetch join token file
    ansible.builtin.fetch:
      src: /home/ubuntu/join-command.sh
      dest: ./join-command.sh
      flat: yes
      validate_checksum: false
```

## Create ansible.cfg
```
[defaults]
remote_user = ubuntu
private_key_file = ./k8s
host_key_checking = False
```

## Update main.tf (master node function)
```
provisioner "local-exec" {
    command = "ansible-playbook -i '${self.public_ip},' playbook.yml"
}
```

## Create outputs.tf
```
output "master" {
  value = aws_instance.k8s_master.public_ip
}

output "workers" {
  value = aws_instance.k8s_worker[*].public_ip
}
```

## Luanch instance in AWS console
Navigate to EC2 > Instances > Luanch an instance<br>
Amazon Machine Image (AMI): Amazon Linux 2 Kernel 5.10 AMI 2.0.20231020.1 x86_64 HVM gp2<br>
Create your keypair then ssh <br>
![image](https://github.com/PlaIsMe/kubernetes-cluster/assets/97893528/411ee908-195f-412a-82d1-3a99ced6a9fb)<br>
The private key is the directory to your keypair file<br>

## Create User
Login as IAM Create a User Select Attach policies directly -> Choose Administator Access<br>
Click on the User -> Security credentials -> Create access key -> CLI<br>
Copy the access key, go to MobXterm -> sudo su -> aws configure -> paste the key then do the command
```
yum install git -y

pip3 install ansible

echo "export PATH=$PATH:/usr/local/bin/" >> ~/.bashrc
source ~/.bashrc

sudo yum install -y yum-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
```

## Create cluster
Clone the git that contains your tf files<br>
cd into the file <br>
Run the code
```
terraform init
terraform apply -auto-approve
```
Then this failure will appear<br>
![image](https://github.com/PlaIsMe/kubernetes-cluster/assets/97893528/200f348d-2d6d-4c82-b0fc-d57377739e50)
<br>Run the code
```
chmod 400 k8s
ansible-playbook -i '{failed_ip,' playbook.yml
rm -f join-command.sh
terraform destroy -auto-approve
terraform apply -auto-approve
```
Here is the result
![image](https://github.com/PlaIsMe/kubernetes-cluster/assets/97893528/c559ff36-6e1e-47ca-b471-e0df77d441bc)


