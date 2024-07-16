# Project Tasks Overview

This README provides a detailed overview of the tasks completed for deploying a simple Node.js application in a Docker container, creating a Kubernetes deployment configuration, and provisioning resources and configuration management through Terraform and Ansible.

## Task 1: Simple Node.js Application Deployment on Docker Container

### Description
This task involves creating a Dockerfile to deploy a simple Node.js application that listens on port 3000. The Dockerfile makes use of a lightweight base image, installs the necessary dependencies, copies the application code, and specifies the command to run the application.

### Deliverables
- `Dockerfile`

### Dockerfile
```dockerfile
# Use a lightweight node image
FROM node:14-alpine

# Set the working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package.json ./
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose application on port 3000
EXPOSE 3000

# Command to run the application
CMD ["node", "app.js"]

```





## Task 2: Kubernetes Deployment

### Description
This task involves creating a Kubernetes deployment configuration for a web application using the nginx:latest image. The deployment should have 3 replicas, expose port 80, and include both liveness and readiness probes. It should also ensure guaranteed QOS for deployments.


### Deliverables
- `deployment.yaml`

### deployment.yaml
```deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "64Mi"
            cpu: "250m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10

```



## Task3: Resource Provisioning and Configuration Management through Terraform and Ansible


### Description
This task involves:
Creating a Terraform script to provision an EC2 instance with necessary security group and VPC configurations.
Configuring the instance with an NGINX web server and other necessary configurations.
Deploying the Node.js application created in Task 1 on the same NGINX web server using Ansible.


### Deliverables
- `main.tf`
- `variable.tf`
- `output.tf`
- `terraform.tfvars`


- `Ansible playbooks and roles`
- `NGINX configuration files`



### main.tf
```main.tf
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main_vpc"
  }
}

resource "aws_subnet" "main" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "main_subnet"
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main_igw"
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "main_rt"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id      = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "web_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web_sg"
  }
}

resource "aws_instance" "web" {
  ami                    = "ami-0c2af51e265bd5e0e" # Ubuntu 22.04 LTS AMI for ap-south-1
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.main.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "nginx_web_server"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
            EOF
}
```


### variable.tf
```variable.tf
variable "key_name" {
  description = "The name of the key pair to use for SSH access."
  type        = string
}
```

### output.tf
```output.tf
output "instance_public_ip" {
  description = "The public IP address of the EC2 instance"
  value       = aws_instance.web.public_ip
}
```

### terraform.tfvars 
```terraform.tfvars 
key_name = "web-cluse"
```





## Task 3: Ansible Nginx and Node.js Deployment


### Description
This Ansible playbook sets up an Nginx server and deploys a Node.js application inside a Docker container. It also configures Nginx as a reverse proxy to forward requests to the Node.js application.


### Prerequisites
- `Ansible installed on your local machine.`
- `An SSH key pair set up for the Ansible user on the target server.`
- `The target server should be an Ubuntu instance.`
- `The path to the SSH private key file, which has permissions to access the target server.l`

### Deliverables
- `hosts.ini`
- `nginx_setup.yml`


### hosts.ini
```hosts.ini
3.110.218.31 ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/web-cluse.pem

```

### nginx_setup.yml
```nginx_setup.yml
---
- name: Setup Nginx and Deploy Node.js App
  hosts: webserver
  become: yes
  tasks:
    - name: Update aptitude cache and upgrade the system packages
      apt:
        update_cache: yes
        upgrade: dist
        cache_valid_time: 3600

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Start and enable Nginx service
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Install dependencies for Docker
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - software-properties-common
        state: present

    - name: Add Docker official GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker repository
      apt_repository:
        repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present

    - name: Install Docker
      apt:
        name: docker-ce
        state: present

    - name: Ensure Docker service is started
      service:
        name: docker
        state: started
        enabled: yes

    - name: Install Docker Compose
      get_url:
        url: "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-{{ ansible_system | lower }}-{{ ansible_architecture }}"
        dest: /usr/local/bin/docker-compose
        mode: '0755'

    - name: Create application directory
      file:
        path: /home/ubuntu/app
        state: directory

    - name: Copy Node.js application Dockerfile
      copy:
        src: /home/ubuntu/node-react-jenkins/api/Dockerfile
        dest: /home/ubuntu/app/Dockerfile

    - name: Synchronize Node.js application files
      synchronize:
        src: /home/ubuntu/node-react-jenkins/api/
        dest: /home/ubuntu/app/
        rsync_opts:
          - "--exclude Dockerfile"
    
    - name: Build Docker image
      command: docker build -t nodejs-app .
      args:
        chdir: /home/ubuntu/app

    - name: Run Docker container
      docker_container:
        name: nodejs-app
        image: nodejs-app
        state: started
        ports:
          - "3000:3000"

    - name: Configure Nginx as reverse proxy
      copy:
        content: |
          server {
              listen 80;

              location / {
                  proxy_pass http://localhost:3000;
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection 'upgrade';
                  proxy_set_header Host $host;
                  proxy_cache_bypass $http_upgrade;
              }
          }
        dest: /etc/nginx/sites-available/default
        owner: root
        group: root
        mode: 0644

    - name: Restart Nginx service
      service:
        name: nginx
        state: restarted
```






## Task 2: Ansible Nginx and Node.js Deployment


### Description
This Ansible playbook sets up an Nginx server and deploys a Node.js application inside a Docker container. It also configures Nginx as a reverse proxy to forward requests to the Node.js application.


### Prerequisites
- `Ansible installed on your local machine.`
- `An SSH key pair set up for the Ansible user on the target server.`
- `The target server should be an Ubuntu instance.`
- `The path to the SSH private key file, which has permissions to access the target server.l`

### Deliverables
- `hosts.ini`
- `nginx_setup.yml`


### hosts.ini
```hosts.ini
3.110.218.31 ansible_user=ubuntu ansible_ssh_private_key_file=/home/ubuntu/web-cluse.pem

```

### nginx_setup.yml
```nginx_setup.yml
---
- name: Setup Nginx and Deploy Node.js App
  hosts: webserver
  become: yes
  tasks:
    - name: Update aptitude cache and upgrade the system packages
      apt:
        update_cache: yes
        upgrade: dist
        cache_valid_time: 3600

    - name: Install Nginx
      apt:
        name: nginx
        state: present

    - name: Start and enable Nginx service
      service:
        name: nginx
        state: started
        enabled: yes

    - name: Install dependencies for Docker
      apt:
        name:
          - apt-transport-https
          - ca-certificates
          - curl
          - software-properties-common
        state: present

    - name: Add Docker official GPG key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker repository
      apt_repository:
        repo: "deb [arch=amd64] https://download.docker.com/linux/ubuntu {{ ansible_distribution_release }} stable"
        state: present

    - name: Install Docker
      apt:
        name: docker-ce
        state: present

    - name: Ensure Docker service is started
      service:
        name: docker
        state: started
        enabled: yes

    - name: Install Docker Compose
      get_url:
        url: "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-{{ ansible_system | lower }}-{{ ansible_architecture }}"
        dest: /usr/local/bin/docker-compose
        mode: '0755'

    - name: Create application directory
      file:
        path: /home/ubuntu/app
        state: directory

    - name: Copy Node.js application Dockerfile
      copy:
        src: /home/ubuntu/node-react-jenkins/api/Dockerfile
        dest: /home/ubuntu/app/Dockerfile

    - name: Synchronize Node.js application files
      synchronize:
        src: /home/ubuntu/node-react-jenkins/api/
        dest: /home/ubuntu/app/
        rsync_opts:
          - "--exclude Dockerfile"
    
    - name: Build Docker image
      command: docker build -t nodejs-app .
      args:
        chdir: /home/ubuntu/app

    - name: Run Docker container
      docker_container:
        name: nodejs-app
        image: nodejs-app
        state: started
        ports:
          - "3000:3000"

    - name: Configure Nginx as reverse proxy
      copy:
        content: |
          server {
              listen 80;

              location / {
                  proxy_pass http://localhost:3000;
                  proxy_http_version 1.1;
                  proxy_set_header Upgrade $http_upgrade;
                  proxy_set_header Connection 'upgrade';
                  proxy_set_header Host $host;
                  proxy_cache_bypass $http_upgrade;
              }
          }
        dest: /etc/nginx/sites-available/default
        owner: root
        group: root
        mode: 0644

    - name: Restart Nginx service
      service:
        name: nginx
        state: restarted
```



### Usage

### Deliverables
- `Navigate to the directory containing the inventory file and playbook file`
- `nginx_setup.yml`


### Navigate to the directory containing the inventory file and playbook file
```Navigate to the directory containing the inventory file and playbook file
cd /path/to/practical-web/ansible

```
### Run the Ansible playbook using the ansible-playbook command.
```Run the Ansible playbook using the ansible-playbook command.
ansible-playbook -i hosts.ini nginx_setup.yml

```

### Execution Instructions

### Docker Deployment
- `Navigate to the directory containing the inventory file and playbook file`
- `nginx_setup.yml`


### Build the Docker image
```Build the Docker image
docker build -t mynodeapp .

```
### Run the Docker container
```Run the Docker container
docker run -it -p 3000:3000 mynodeapp

```


### Execution Instructions

### Docker Deployment
- `Navigate to the directory containing the inventory file and playbook file`
- `nginx_setup.yml`


### Build the Docker image
```Build the Docker image
docker build -t mynodeapp .

```
### Run the Docker container
```Run the Docker container
docker run -it -p 3000:3000 mynodeapp

```

### Kubernetes Deployment

### Apply the deployment configuration
```Apply the deployment configuration

kubectl apply -f deployment.yaml

```
### Run the Docker container
```Run the Docker container
docker run -it -p 3000:3000 mynodeapp

```
### Provisioning and Configuration with Terraform and Ansible
```Provisioning and Configuration with Terraform and Ansible
terraform init
terraform fmt
terraform plan
terraform apply -var="key_name=web-cluse"

```

### Run the Ansible playbook
```Run the Ansible playbook
ansible-playbook -i hosts.ini nginx_setup.yml
```
This covers all the tasks, configurations, and instructions needed to reproduce the work done in this project.
