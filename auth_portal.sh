#!/bin/bash

# Check if Docker is installed
if command -v docker &> /dev/null; then
    echo "Docker is installed. Proceeding with setup..."

    # Remove Docker containers and images
    sudo docker rm -vf $(sudo docker ps -aq)
    sudo docker rmi -f $(sudo docker images -aq)

    # Remove Tutor files
    sudo rm -rf "$(tutor config printroot)"
    sudo rm -rf /usr/local/bin/tutor

    # Auto remove unused packages
    sudo apt autoremove -y

    # Ensure Docker starts on boot
    sudo systemctl enable docker

    # Download and install Tutor binary
    sudo curl -L "https://github.com/overhangio/tutor/releases/download/v13.1.5/tutor-$(uname -s)_$(uname -m)" -o /usr/local/bin/tutor
    sudo chmod 0755 /usr/local/bin/tutor

else
    echo "Docker is not installed. Installing Docker and dependencies..."

    # Install necessary dependencies
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gnupg lsb-release jq

    # Set up Docker repository
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker.io

    # Add current user to Docker group
    sudo usermod -aG docker $USER
    sudo chown $USER:docker /var/run/docker.sock

    # Install Docker Compose
    sudo curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose

    # Ensure Docker starts on boot
    sudo systemctl enable docker

    # Download and install Tutor binary
    sudo curl -L "https://github.com/overhangio/tutor/releases/download/v13.1.5/tutor-$(uname -s)_$(uname -m)" -o /usr/local/bin/tutor
    sudo chmod 0755 /usr/local/bin/tutor
fi

# Prompt for user input
echo "Enter LMS_HOST_DOMAIN Name:"
read LMS_HOST_DOMAIN
echo "Enter Course Email:"
read COURSE_EMAIL
echo "Enter CONTACT EMAIL:"
read CONTACT_EMAIL

# Enable Tutor plugins
tutor plugins enable forum && tutor config save

# Tutor configuration
tutor config save --set CMS_HOST="studio.$LMS_HOST_DOMAIN" \
                  --set LMS_HOST_DOMAIN="$LMS_HOST_DOMAIN" \
                  --set ENABLE_HTTPS=true \
                  --set CONTACT_EMAIL="$CONTACT_EMAIL"

# Update `lms.env.json` file with course email
lms_env_file="$(tutor config printroot)/env/apps/openedx/config/lms.env.json"
sudo apt-get install -y jq
sudo jq --arg COURSE_EMAIL "$COURSE_EMAIL" '. | . + { "COURSE_EMAIL": $COURSE_EMAIL }' "$lms_env_file" > tmp.json && sudo mv tmp.json "$lms_env_file"

# Prompt for Docker credentials
echo "Enter Docker Username:"
read DOCKER_USERNAME
echo "Enter Docker Password:"
read -s DOCKER_PASSWORD  # -s to hide the password input

# Login to Docker
echo "$DOCKER_PASSWORD" | sudo docker login --username "$DOCKER_USERNAME" --password-stdin
if [ $? -ne 0 ]; then
    echo "Docker login failed. Exiting..."
    exit 1
fi

# Update LMS and LMS worker Docker image in `docker-compose.yml`
YAML_FILE=".local/share/tutor/env/local/docker-compose.yml"
NEW_IMAGE="7503444967/sau-custom-lms-theme:1.0"
sudo sed -i "/^ *lms:/,/^ *[^ ]/ s|image: docker.io/overhangio/openedx:13.1.5|image: $NEW_IMAGE|" "$YAML_FILE"
sudo sed -i "/^ *lms-worker:/,/^ *[^ ]/ s|image: docker.io/overhangio/openedx:13.1.5|image: $NEW_IMAGE|" "$YAML_FILE"

# Set Tutor theme
tutor local settheme edx-reborn-indigo

# Restart Tutor
tutor local stop && tutor local start -d

echo "Work complete. Your $LMS_HOST_DOMAIN portal is ready"
echo "Thank you!"
