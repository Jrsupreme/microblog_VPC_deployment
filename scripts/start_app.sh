#!/bin/bash

#This script will ssh into the Application_server and run the start_app.sh script.

scp -i /home/ubuntu/.ssh/workload4.pem ./start_app.sh  ubuntu@10.0.115.121:/home/ubuntu/start_app.sh   #scp start_app.sh into the application server.

ssh -i /home/ubuntu/.ssh/workload4.pem ubuntu@10.0.115.121 "souce ./start_app.sh"
													#run the start_app script
