# Untitled

# Workload 4

In this workload, we will improve the security of the application while also making it more efficient. The focus is on building and configuring a custom server infrastructure using AWS services, specifically setting up a Virtual Private Cloud (VPC) with multiple subnets to host and deploy a web application.

First, **clone the application repository to your own repository**.

### Create a Custom VPC

We are creating a custom VPC to enhance security and network configuration, allowing us to control which resources are available to the public or kept private. This further enhances the security of our infrastructure.

### Steps:

1. Navigate to **VPC** in the AWS Console.
2. Create a VPC named `microblog-app-vpc`.
3. Configure VPC settings:
    - Select 1 Availability Zone, 1 public subnet, and 1 private subnet.
4. For the NAT gateway, select 1 in the AZ.
5. Set **VPC Endpoints** to None.
6. Ensure that **DNS Hostname** and **DNS Resolution** are both checked.

### Subnets and NAT Gateway

Configuring public and private subnets, along with the NAT Gateway, is critical because they control local resource access and internet access. Ensure resources meant for public access are in the public subnet, while those that should remain private are kept within the private subnet.

### Steps:

1. In the VPC console, navigate to **Subnets**.
2. Select the public subnet you just created.
3. Click on the **Actions** dropdown menu in the top right corner.
4. Select **Edit Subnet Settings**.
5. Under **Auto-assign IP Settings**, check **Enable auto-assign public IPv4 address**, then apply changes.
6. Navigate to **NAT Gateway** under VPC.
7. Create a NAT Gateway named `Microblog-app-NATgateway`.
    - Ensure you select the **Public Subnet** from the dropdown.
8. Set **Connectivity Type** to **Public**.
9. Allocate an Elastic IP and create the NAT Gateway.
10. Navigate to **Route Tables** in VPC.
11. Select **Edit Routes** from the **Actions** dropdown menu.
12. Add a new route and select the NAT Gateway.

### Setting Up EC2 Servers

Now that the perimeter is secure, it's time to add our EC2 servers. By separating different parts of the application architecture across security layers, we ensure redundancy and resilience, minimizing single points of failure.

### Steps:

1. Launch a `t3.medium` EC2 instance in the default VPC for Jenkins and all necessary dependencies.
2. Launch a `t3.micro` EC2 instance in the custom VPC public subnet for the **Web Server**. Set up security groups to allow traffic on ports 80 and 22 (HTTP & SSH).
3. Launch a `t3.micro` EC2 instance in the custom VPC private subnet for the **Application Server**. Set up security groups to allow traffic on ports 22 and 5000 (SSH & Gunicorn). Save the key pair.

### SSH Configuration

1. SSH into the Jenkins server and run:

```bash
bash
Copy code
ssh-keygen
# Specify the absolute path for the key file.

```

1. Copy the `.pub` key generated and append it to the `authorized_keys` file on the Web Server.
2. SSH into the Web Server from the Jenkins server. This action makes the Jenkins server a **known host**, meaning its SSH connection has been verified, and the fingerprint key has been saved.

```bash
bash
Copy code
ssh -i <key_path> ubuntu@<Web_server_public_IP>

```

1. Copy the Application Server key to the Web Server to enable SSH connectivity between them.
2. Test the connection by SSH-ing into the Application Server from the Web Server.

### Nginx Configuration

Nginx serves as our reverse proxy server, redirecting HTTP traffic from port 80 to Gunicorn on the Application Server (port 5000). Proper configuration ensures secure and efficient traffic flow to the application.

### Steps:

1. SSH into the Web Server and install Nginx.
2. After installation, modify the `sites-enabled/default` file located at `/etc/nginx/sites-enabled/default`.
3. Replace the following lines with the **Application Server's private IP**:

```bash
bash
Copy code
location / {
    proxy_pass http://<private_IP>:5000;
    proxy_set_header Host $host;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}

```

1. Test the configuration by running:

```bash
bash
Copy code
sudo nginx -t

```

1. If successful, the following message will appear:

```bash
bash
Copy code
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful

```

1. Restart Nginx:

```bash
bash
Copy code
sudo systemctl restart nginx
sudo systemctl status nginx

```

### Scripts

Automation is crucial to increase efficiency and reduce human error. For this deployment, we automate the setup and start of the application using two scripts.

### `setup.sh` (from the Web Server)

```bash
bash
Copy code
#!/bin/bash
# This script SSHes into the Application Server and runs the start_app.sh script.

ssh -i /home/ubuntu/.ssh/workload4.pem ubuntu@10.0.115.121 "source /home/ubuntu/microblog_VPC_deployment/scripts/start_app.sh"

```

### `start_app.sh` (from the Application Server)

```bash
bash
Copy code
#!/bin/bash

# This script installs all application dependencies, sets up environment variables, and runs Gunicorn in the background.

# Step 1: Update and install dependencies
echo "Updating and installing dependencies..."
sudo apt update
sudo apt install fontconfig openjdk-17-jre software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.9 python3.9-venv python3-pip nginx -y

# Step 2: Clone the repository
git clone https://github.com/Jrsupreme/microblog_VPC_deployment.git

# Step 3: Navigate to the application directory
cd ~/microblog_VPC_deployment

# Step 4: Create and activate a virtual environment
python3.9 -m venv venv
source venv/bin/activate

# Step 5: Install application dependencies
pip install -r requirements.txt
pip install gunicorn pymysql cryptography

# Step 6: Set the FLASK_APP environment variable
export FLASK_APP=microblog.py

# Step 7: Set up the database
flask translate compile
flask db upgrade

# Step 8: Start Gunicorn in the background
gunicorn -b :5000 -w 4 microblog:app --daemon

```

In this case, we run `start_app.sh` with `source` to ensure that environment variables like `FLASK_APP` persist after the script finishes. If run in a new subshell, such changes wouldn’t affect the current shell session.

### Jenkins Pipeline

Setting up a Jenkins pipeline allows for continuous integration and continuous deployment (CI/CD). This automates the testing and deployment process, reducing human error, speeding up development, and ensuring consistent builds.

*This documentation was revised for clarity and grammar with help from OpenAI's ChatGPT, which assisted in optimizing the content without altering the original code or steps.*