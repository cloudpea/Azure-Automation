#!/bin/bash
# Version 1.0
# Installs and configures Ansible, Curl & Python

# Command usage: InstallAnsible.sh $ANSIBLE_USER
export ANSIBLE_USER=${ansible_username}
export INVENTORY_FILE=${inventory_file_contents}
export GIT_URL=${ansible_git_url}
export GIT_REPO=$(echo $GIT_URL | sed 's#.*/##')


# Update Packages
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Curl
if [ ! $(which curl) ]; then
  sudo apt-get install -y curl
fi

# Install Python
if [ ! $(which python) ]; then
  sudo apt-get install -y python
fi

# Install AZ CLI
if [ ! $(which az) ]; then
  curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
  sudo add-apt-repository -y "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main"
  sudo apt-get -y update
  sudo apt-get -y install apt-transport-https azure-cli

# Install WhoIs
if [ ! $(which whois) ]; then
  sudo apt install whois -y
fi

# Install Git
if [ ! $(which git) ]; then
  sudo apt install git -y
fi

# Install Ansible
if [ ! $(which ansible) ]; then
  sudo apt-add-repository ppa:ansible/ansible
  sudo apt-get update
  sudo apt-get install -y ansible 
fi

# Configure Ansible User & SSH Key
if [ ! id -u $ANSIBLE_USER]; then
  useradd -m -s /bin/bash $ANSIBLE_USER
  passwd $ANSIBLE_USER
  echo  -e "$ANSIBLE_USER\tALL=(ALL)\tNOPASSWD:\tALL" > /etc/sudoers.d/$ANSIBLE_USER
  mkpasswd --method=SHA-512
  TYPE THE PASSWORD 'secret01'
  su - $ANSIBLE_USER
  ssh-keygen -t rsa -N ""
fi

# Configure Ansible Inventory
if [! -f /etc/ansible/hosts]; then
  echo $INVENTORY_FILE > /etc/ansible/hosts
fi 

# Clone Ansible Playbook Repository
if [! -d $HOME/git/ ]; then
  mkdir $HOME/git/
  cd $HOME/git/
  git clone $GIT_URL
  crontab -l | { cat; echo "0 9 * * * cd $HOME/git/$GIT_REPO && git pull"; } | crontab -
fi