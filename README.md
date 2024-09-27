# Workload 4

In this workload we will be dialing in our security, while also making the application more effective and secure. In this workload

Clone application repository to your own repository

### Create a custom VPC

The reason we are creating a custom VPC is because it allows for better security and network configuration, allowing us to choose what resources are available to the public or kept private. Further enhancing the security of our infrastructure.

Steps:

1. Navigate to VPC in AWS Console.
2. Create VPC: microblog-app-vpc.
3. VPC and more.
4. Select: 1 Availability zone, 1 public subnet, and 1 private subnet.
5. For NAT gateway select: 1 in AZ.
6. VPC endpoints: None.
7. Ensure that DNS hostname and DNS resolution are both checked.

### Subnets and NAT Gateway

Ensuring that our public and private subnets and NAT gateway are configured correctly is critical, since they control our local resource access aswell as the access to the internet. We want to ensure that, the rources we want to be available to the public are in the public subnet and what the public isn’t supposed to see stays local within the private subnet.

Steps:

1. While on the VPC console, navigate to subnets.
2. Select the public subnet we just created.
3. On the top right corner click on the “Action” dropdown menu.
4. Select “Edit subnet settings” .
5. Under “**Auto-assign IP settings**” ensure that “Enable auto-assign public IPv4 address” is checked then Apply changes.
6. Under VPC navigate to NAT Gateway.
7. Create a NAT Gateway: Microblog-app-NATgateway.
8. Make sure to SELECT the PUBLIC SUBNET we created within our VPC from the subnet dropdown menu (otherwise the private subnet won’t have access to the internet through this NATgw).
9. For connectivity type select: public.
10. Allocate an Elastic IP. Click in create NAT Gateway.
11. Under VPC navigate to Route Tables.
12. Select “edit routes” from the “Actions” dropdown menu.
13. Add a new open route and select the NAT Gateway we just created.

### Setting up EC2 Servers

Now that we have the perimeter secured is time to add our building blocks, the EC2 servers. By  adding multiple servers and separating different parts of our application architecure across security layers we ensure a more effective and secure architecture by adding redundacy and resiliency. Making sure we have as little single points of failure as posible.

Steps:

1. Launch a t3.medium EC2 within the default VPC install Jenkins and all necessary dependencies.
2. Launch a t3.micro within our custom VPC public subnet for the “Web_server”. Setup security groups to allow traffic on port 80, and 22 (HTTP & SSH).
3. Launch a t3.micro within our custom VPC private subnet for the “Application_server”. Setup security groups to allow traffic on port 22, and 5000 (SSH & Gunicorn). Make sure to save the key pair.

### SSH Configuration

1. SSH into the “Jenkins server”. Run: 

```bash
ssh-keygen
#type in the absolute path to where you want the key file to be saved.
```

1. Copy the .pub key that was generated, and append it to the “authorized_keys” file in the Web_server
2. SSH to the Web_server from the “Jenkins server”. By doing this the “Jenkins server” becomes a known_host. Being a know host means that our ssh conection has been verified and our “fingerprint” key has been saved. 

```bash
ssh -i <key_path> ubuntu@<Web_server_public_IP>
```

1. Copy the “Application_server” key into the “Web_sever” to allow for SSH connectivity between the “Web Server” and “Application Server”.
2. Test the connection by SSH'ing into the "Application_Server" from the "Web_Server". 

### Nginx Configuration

Nginx is our reverse proxy server, it will be in charge or redirecting http traffic from port 80 to gunicorn in our application server on port 5000. It is very important that we configure Nginx properly to ensure that secure and efficient traffic to our application.

Steps:

1. SSH into the Web_server and install nginx.
2. After nginx is installed, modify the “`sites-enabled/default`” file. The file should located in:  `/etc/nginx/sites-enabled/default`
3. Once inside the file, replace the following

```bash
#Replace "private_IP" with the Application_server's private IP
location / {
proxy_pass http://<private_IP>:5000;
proxy_set_header Host $host;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
}
```

1. To test that the settings were saved and work run:

```bash
sudo nginx -t  
```

1. If the test was successful there should be a confirmation that looks like this:

```bash
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

1. Restart Nginx

```bash
sudo systemctl restart nginx
#confirm that nginx was restarted
sudo systemctl status nginx
```

### Scripts

As cloud engineers our job is to automate repetitive proccesses. Automating increases efficiency and ensures consistency while also reducing human error. For this deployment we’ll be autamating the setup, installation, and start of our application by running the following scripts:

### `setup.sh`(from the Web_server)

```bash
#!/bin/bash

#This script will ssh into the Application_server and run the start_app.sh script.

ssh -i /home/ubuntu/.ssh/workload4.pem ubuntu@10.0.115.121 "souce /home/ubuntu/microblog_VPC_deployment/scripts/start_app.sh" #ssh into the application server and run the start_app.sh script
```

### `start_app.sh`(from the Application_server)

```bash
#!/bin/bash

#This script will install all of application dependencies, set up environmental variables and run gunicorn in the background
#Install python3.9 dependencies and nginx
#setup flask environmental variable
#setup database
#run gunicorn in the background
  
#Steps:

#Step 1: Update and install dependencies

echo "Updating and installing dependencies..."
sudo apt update
sudo apt install fontconfig openjdk-17-jre software-properties-common -y && sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt install python3.9 python3.9-venv python3-pip nginx -y

#Step 2: Clone the repository

git clone https://github.com/Jrsupreme/microblog_VPC_deployment.git

#Step 3: Navigate to the application directory

cd ~/microblog_VPC_deployment

#Step 4: Create and activate a virtual environment

echo "Creating virtual environment..."
python3.9 -m venv venv
source venv/bin/activate

#Step 5: Install application dependencies

echo "Installing application dependencies..."
pip install -r requirements.txt
pip install gunicorn pymysql cryptography

#Step 6: Set the FLASK_APP environment variable

echo "Setting environment variables..."
export FLASK_APP=microblog.py
echo "FLASK_APP=microblog.py was set" 

#Step 7: Set up the data base

echo "Setting up the data base..."
flask translate compile
flask db upgrade

#Step 8: Start Gunicorn in the background

echo "Starting application with Gunicorn..."
gunicorn -b :5000 -w 4 microblog:app --daemon #running gunicorn in the background as a daemon for simplicity of execution

echo "Application server setup complete and Gunicorn in the background as a daemon."

```

In this occastion we are running the `start_app.sh` script with “`source`” because it executes the script in the “**current shell session**”, meaning any changes to environment variables or working directories will persist after the script finishes. In the other hand, if the script permissions were changed or we used bash to execute the script, it would run in a “**new subshell”**. Any environment changes (like setting variables) will not affect the current shell session once the script finishes. Since we are changing the “`FLASK_APP`” environmental variable, the changes need to persist after the script finishes in order for our application to keep running properly.

### Jenkins Pipeline

Setting up a Jenkins pipeline allows for continuous integration and continuous deployment (CI/CD), ensuring that any changes to the code are automatically tested and deployed efficiently. This process reduces the chances of human error, speeds up development, and ensures consistent, repeatable builds across different environments. By automating the build, test, and deployment stages, we streamline the development workflow, allowing for faster delivery of updates and more reliable application performance.

### Issues & Troubleshooting

ISSUE: Was not able to connect to webserver EC2. Why?: Created an EC2 before enabling “Auto assign IPv4 addresses” on the public subnet settings. 

Solution: Terminate already created EC2s that were not assign a public IP and create new ones after the setting was changed. 

ISSUE:  Could not isntall python3.9 in the application server. Why?: The package manager (`apt`) was unable to find Python 3.9 or the related packages in its default repository Solution: Add a repository that provides Python 3.9 before installing it. Used the following modified code from Workload 1: 

```bash
#one liner from workload 1
sudo apt update && sudo apt install fontconfig openjdk-17-jre software-properties-common && sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt install python3.7 python3.7-venv
#replace python3.7 with python3.9 and add -y after "software-properties-common" and "python3.9 python3.9-venv python3-pip nginx" to eliminate the need for input. Should look like this:
sudo apt update 
sudo apt install fontconfig openjdk-17-jre software-properties-common -y && sudo add-apt-repository ppa:deadsnakes/ppa && sudo apt install python3.9 python3.9-venv python3-pip nginx -y
```

ISSUE: Could not ssh into the Web_server from the Jenkins server using the private ip. 

Why?: Route table was not configure to route traffict to the Custom microblog app VPC.

Solution: Added a route with the cidr block from the custom vpc to the route table belonging to the default vpc.

ISSUE: Jenkins was failing to start. 

Why? Job for jenkins.service failed because the control process exited with error code.

Solution: 

```bash
#unistall jenkins
sudo apt remove --purge jenkins
#ensure that fontconfig and deadsnake is installed
sudo apt install fontconfig openjdk-17-jre software-properties-common -y && sudo add-apt-repository ppa:deadsnakes/ppa
#update and upgrade bin and libs
sudo apt update && sudo apt upgrade
#install jenkins again
sudo apt install jenkins -y
 
```