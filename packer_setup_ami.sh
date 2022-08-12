#!/bin/bash
sudo yum update -y
sudo yum install httpd -y
sudo systemctl start httpd
sudo systemctl enable httpd
sudo touch /var/www/html/index.html
sudo chmod 666 /var/www/html/index.html
sudo ls -la /var/www/html/
sudo echo "Hello World at `date +'%Y-%m-%d'`" > /var/www/html/index.html
