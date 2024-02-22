#!/bin/bash

# PURPOSE: Deploys Terraform Agents on a Linux VM.


#This code will log the output of the install to a log file
#for console debuggin you can remark this line to show output to console
exec > /var/log/tfc_Agent_Install.log 2>&1


# Exit immediately if a command returns non-zero exit status.
set -e

# Inputs
# ------------------------------------------------------------------------------------------

#  Inputs as set in Terraform via templatefile function in customdata:
#  TFC_AGENT_1_TOKEN, TFC_AGENT_2_TOKEN etc

# Variables
# ------------------------------------------------------------------------------------------

# Must reference a version as Hashicorp don't provide a 'latest' version url.
AGENT_BINARY_VERSION="${TFC_AGENT_VERSION}"
INSTALL_DIR="/opt/"
INSTANCE_NAME_PREFIX="tfc-agent-"
# Agents meta-data represented as comma-delimited records.
# Format: Agent Name, Instance Name, Agent Token (see: https://developer.hashicorp.com/terraform/tutorials/cloud/cloud-agents)
AGENTS_META_DATA=(
"${TFC_AGENT_1_NAME},${INSTANCE_NAME_PREFIX}1,${TFC_AGENT_1_TOKEN}"
# Next agent: just add another line of values within double quotes here
)

AGENT_LOG_LEVEL="INFO" # Change to TRACE for debugging purposes.
TEMP_DIR="tfc_agent_download"
SERVICE_RESTART_SEC=60

# Functions
# ------------------------------------------------------------------------------------------

# Show progress in standard way.
# Returns: N/A
showProgress () {
    echo -e "\n$1"
}

# Main
# ------------------------------------------------------------------------------------------

showProgress "Creating temp directory..."
sudo rm -rf $TEMP_DIR # Delete if already exists for a clean slate
sudo mkdir -p $TEMP_DIR
sudo chmod 707 $TEMP_DIR
cd $TEMP_DIR


# Main
# --------------------------------INSTALLING POWERSHELL------------------------------------------------

showProgress "Setting up Powershell..."

showProgress "Updating list of packages..."
# IMPORTANT: apt-get more stable in scripts than apt.
sudo apt-get -y update
sudo apt-get -y upgrade

showProgress "Downloading Powershell package..."

wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb

showProgress "Installing Powershell..."
sudo dpkg -i packages-microsoft-prod.deb

showProgress "Resolve missing dependencies and finish Powershell install..."
sudo apt-get -y update
sudo apt-get install powershell -y -f


showProgress "Installing Powershell modules..."
pwsh -Command "Install-Module -Name Az -Repository PSGallery -Force -Scope AllUsers"
pwsh -Command "Install-Module -Name MSGraph -Repository PSGallery -Force -Scope AllUsers"
pwsh -Command "Install-Module AzureAD.Standard.Preview -Repository PSGallery -Force -Scope AllUsers"

# --------------------------------INSTALLING AZURE-CLI-----------------------------------------------

# Make sure required supporting packages are installed
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg -y -f

#download the correct Microsoft signing key
curl -sL https://packages.microsoft.com/keys/microsoft.asc | \
    gpg --dearmor | \
    sudo tee /etc/apt/trusted.gpg.d/microsoft.gpg > /dev/null

#Add this this os the Azure CLI softway repository
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/azure-cli.list

#update again as we have added a new repository
sudo apt-get update

#install
sudo apt-get install azure-cli

# Main
# --------------------------------INSTALLING TERRAFORM-----------------------------------------------


showProgress "Setting up Terraform..."


showProgress "Deleting any previous Terraform Agent installs..."
for dir in ${INSTALL_DIR}${INSTANCE_NAME_PREFIX}*
do
   sudo rm -rf $dir
done

showProgress "Deleting any previous Terraform Agent Services..."
for record in "${AGENTS_META_DATA[@]}"
do
    # Split record into variables using IFS as the comma
    IFS=',' read -r agentName instanceName token <<< "$record"
    
    # If Service exists...
    if [ $(systemctl show -p SubState --value ${instanceName}.service) != "dead" ];then
        showProgress "${instanceName} Service found. Deleting..."
        # Stop and disable service.
        sudo systemctl stop ${instanceName}.service
        sudo systemctl disable ${instanceName}.service

        # Remove Service file and any symlink related to it
        sudo rm /etc/systemd/system/${instanceName}.service
        sudo rm -f /usr/lib/systemd/system/${instanceName}.service

        # Reload Systemd to apply changes.
        sudo systemctl daemon-reload
	else
		showProgress "${instanceName}.service not found."
	fi
done


showProgress "Downloading binaries and signature files..."
# IMPORTANT: Install of tfc-agent files via apt (and other package managers) is not yet supported.
curl -Os https://releases.hashicorp.com/tfc-agent/${AGENT_BINARY_VERSION}/tfc-agent_${AGENT_BINARY_VERSION}_linux_amd64.zip
curl -Os https://releases.hashicorp.com/tfc-agent/${AGENT_BINARY_VERSION}/tfc-agent_${AGENT_BINARY_VERSION}_SHA256SUMS
curl -Os https://releases.hashicorp.com/tfc-agent/${AGENT_BINARY_VERSION}/tfc-agent_${AGENT_BINARY_VERSION}_SHA256SUMS.sig

# Sources: 
# https://www.hashicorp.com/security
# https://developer.hashicorp.com/terraform/tutorials/cli/verify-archive
showProgress "Verifying binaries..."
# Download Hashicorp's public keys.
curl --remote-name https://keybase.io/hashicorp/pgp_keys.asc
# Import Keys into GPG Keychain
showProgress "1"
gpg --import pgp_keys.asc
showProgress "2"
# Verify the signature file is untampered.
showProgress "3"
gpg --verify tfc-agent_${AGENT_BINARY_VERSION}_SHA256SUMS.sig tfc-agent_${AGENT_BINARY_VERSION}_SHA256SUMS
# Verify the SHASUM matches the archive.
showProgress "4"
shasum --algorithm 256 --check tfc-agent_${AGENT_BINARY_VERSION}_SHA256SUMS

showProgress "Decompressing Terraform Agent binaries..."
sudo apt-get install unzip
unzip tfc-agent_${AGENT_BINARY_VERSION}_linux_amd64.zip -d binaries

showProgress "Installing Terraform Agents..."	
for record in "${AGENTS_META_DATA[@]}"
do
    # Split record into variables using IFS as the comma
    IFS=',' read -r agentName instanceName token <<< "$record"
	
    dir=${INSTALL_DIR}${instanceName}
    showProgress "Installing Terraform Agent '${agentName}' into ${dir}..."	
	sudo mkdir -p $dir
	sudo chmod 707 $dir
	sudo cp binaries/tfc-agent* $dir	
	
	# Create .env file for running the Agent as a Service via Systemd
	cat > ${dir}/tfc-agent.env << EOF
TFC_AGENT_TOKEN=$token
TFC_AGENT_NAME=$agentName
TFC_AGENT_LOG_LEVEL=$AGENT_LOG_LEVEL
EOF

    showProgress "Creating Terraform Agent '${agentName}' Service..."
	sudo touch /etc/systemd/system/${instanceName}.service
	sudo chmod 707 /etc/systemd/system/${instanceName}.service	
    cat > /etc/systemd/system/${instanceName}.service << EOF
[Unit]
Description=Service to automatically start $agentName
After=network.target

[Install]
WantedBy=multi-user.target

[Service]
EnvironmentFile=${dir}/tfc-agent.env
Type=simple
ExecStart=${dir}/tfc-agent
KillSignal=SIGINT
WorkingDirectory=$dir
Restart=always
RestartSec=$SERVICE_RESTART_SEC
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=%n
EOF

    # Reload Systemd to apply changes.
    sudo systemctl daemon-reload

    # Enable and start the Service
    sudo systemctl enable $instanceName
    sudo systemctl start $instanceName
	
done

showProgress "Cleaning up..."
cd -
rm -rf $TEMP_DIR

showProgress "Done!"
