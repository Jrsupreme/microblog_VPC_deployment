pipeline {
  agent any
    stages {
        stage ('Build') {
            steps {
                sh '''#!/bin/bash
                python3.9 -m venv venv
                source venv/bin/activate
		export FLASK_APP=microblog.py
                pip install -r requirements.txt
                pip install gunicorn pymysql cryptography
		flask translate compile
                flask db upgrade
		'''
            }
        }
        stage ('Test') {
            steps {
                sh '''#!/bin/bash
                source venv/bin/activate
                py.test ./test/unit/ --verbose --junit-xml test-reports/results.xml
                '''
            }
            post {
                always {
                    junit 'test-reports/results.xml'
                }
            }
        }
      stage ('OWASP FS SCAN') {
            steps {
                dependencyCheck additionalArguments: '--scan ./ --disableYarnAudit --disableNodeAudit', odcInstallation: 'DP-Check'
                dependencyCheckPublisher pattern: '**/dependency-check-report.xml'
            }
        }
      stage ('Deploy') {
            steps {
                sh '''#!/bin/bash
		ssh -i /home/ubuntu/.ssh/workload4key.pem ubuntu@10.0.50.132 "source ./setup.sh"
		'''
            }
        }
    }
}
