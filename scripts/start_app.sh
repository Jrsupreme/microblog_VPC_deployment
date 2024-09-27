#!/bin/bash

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
