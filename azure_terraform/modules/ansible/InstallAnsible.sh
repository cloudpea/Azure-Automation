#!/bin/bash
# Version 1.0
# Installs and configures Ansible & pip

# Command usage: InstallAnsible.sh $ANSIBLE_USER $GIT_URL
export ANSIBLE_USER=${ansible_username}
export GIT_URL=${ansible_git_url}
export GIT_TOKEN=${ansible_git_token}
export GIT_REPO=$(echo $GIT_URL | sed 's#.*/##')
export AUTH_GIT_URL=$(echo $GIT_URL | sed "s/github.com/$GIT_TOKEN@github.com/g")

# Update Packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install PIP
if [ ! $(which pip) ]; then
  sudo apt install -y python-pip
fi

# Install Ansible
if [ ! $(which ansible) ]; then
  sudo pip install ansible[azure]
fi

# Configure Ansible User & SSH Key
if [ ! -d /home/$ANSIBLE_USER ]; then
  sudo useradd -m -s /bin/bash $ANSIBLE_USER
  sudo mkdir /home/$ANSIBLE_USER/.ssh/
  sudo ssh-keygen -t rsa -N "" -f /home/$ANSIBLE_USER/.ssh/id_rsa
fi

# Clone Ansible Playbook Repository
if [ ! -d /home/$ANSIBLE_USER/git ]; then
  sudo mkdir /home/$ANSIBLE_USER/git
  cd /home/$ANSIBLE_USER/git
  sudo git clone $AUTH_GIT_URL
  crontab -l | { cat; echo "0 9 * * * cd /home/$ANSIBLE_USER/git/$GIT_REPO && git pull"; } | crontab -
fi