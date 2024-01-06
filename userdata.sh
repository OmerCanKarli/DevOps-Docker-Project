#!/bin/bash
dnf update -y
dnf install git -y
dnf install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
newgrp docker
curl -SL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
cd /home/ec2-user
TOKEN=${token}
USER=${user}
git clone https://$TOKEN@github.com/$USER/my_bookapp_repo.git
cd my_bookapp_repo
docker-compose up -d