  #!/bin/bash

  if command -v docker &> /dev/null ; then
      #remove docker images
      docker rm -vf $(docker ps -aq)
      docker rmi -f $(docker images -aq)

      #remove tutor file
      sudo rm -rf "$(tutor config printroot)"

      sudo rm -rf /usr/local/bin/tutor

      # apt auto remove
      sudo apt autoremove -y

      sudo systemctl enable docker

      # git clone tutor binary
      sudo curl -L "https://github.com/overhangio/tutor/releases/download/v13.1.5/tutor-$(uname -s)_$(uname -m)" -o /usr/local/bin/tutor

      # give permission to tutor user
      sudo chmod 0755 /usr/local/bin/tutor

      # take input from user
      echo "Enter LMS_HOST Name:"
      read LMS_HOST
      echo "Enter Course Email:"
      read COURSE_EMAIL
    #   echo "Enter SMTP HOST:"
    #   read SMTP_HOST
      echo "Enter SMTP USERNAME:"
      read SMTP_USERNAME
      echo "Enter SMTP PASSWORD:"
      read SMTP_PASSWORD
      # echo "Enter CONTACT EMAIL:"
      # read CONTACT_EMAIL

      # tutor plugins
      tutor plugins enable forum && tutor config save

      # tutor config for portel
      tutor config save --set CMS_HOST="studio.$LMS_HOST.rcmoocs.in"  \
      --set LMS_HOST="$LMS_HOST.rcmoocs.in"\
      --set ENABLE_HTTPS=true \
      --set SMTP_HOST="email-smtp.ap-south-1.amazonaws.com" \
      --set SMTP_PORT=587 \
      --set SMTP_USE_TLS=true \
      --set SMTP_USERNAME="$SMTP_USERNAME" \
      --set SMTP_PASSWORD="$SMTP_PASSWORD" \
      --set CONTACT_EMAIL="tlc@ramanujancollege.ac.in" \
      
      # Get the path to the lms.env.json file
      lms_env_file="$(tutor config printroot)/env/apps/openedx/config/lms.env.json"
      
      # Add Course Email
      sudo apt-get install jq -y
      jq --arg COURSE_EMAIL "$COURSE_EMAIL" '. | . + { "COURSE_EMAIL": $COURSE_EMAIL }' "$lms_env_file" > tmp.json && mv tmp.json "$lms_env_file"

      #tutor build 
      tutor local start -d

      # tutor migrate
      tutor local init 

      # update lms and lms worker docker image
      YAML_FILE=".local/share/tutor/env/local/docker-compose.yml"
      NEW_IMAGE="7503444967/maple-edx-server:volume-final.1.5-without-pmmmt"

      # Use sed to replace the image line for the 'lms' service
      sed -i "/^ *lms:/,/^ *[^ ]/ s|image: docker.io/overhangio/openedx:13.1.5|image: $NEW_IMAGE|" "$YAML_FILE"  
      sed -i "/^ *lms-worker:/,/^ *[^ ]/ s|image: docker.io/overhangio/openedx:13.1.5|image: $NEW_IMAGE|" "$YAML_FILE" 

      # tutor settheme 
      tutor local settheme edx-reborn-indigo 

      # tutor restart
      tutor local stop && tutor local start -d


      echo "Work complete your $LMS_HOST portal is ready"
      echo "Thank you !!"

  
  else
      # Update the package cache
      sudo apt-get update

      # Install the packages using line continuation
      sudo apt-get install \
      ca-certificates \
      curl \
      gnupg \
      lsb-release -y

      sudo apt-get install jq -y
      # downloading docker for ubutnu
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg -y

      # install docker 
      sudo apt install docker.io -y

      # give permission to docker user
      sudo usermod -aG docker $USER

      sudo chown $USER:docker /var/run/docker.sock

      # install docker compose
      sudo curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose 

      # give permission to docker compose 
      sudo chmod +x /usr/local/bin/docker-compose

      sudo systemctl enable docker

      # git clone tutor binary
      sudo curl -L "https://github.com/overhangio/tutor/releases/download/v13.1.5/tutor-$(uname -s)_$(uname -m)" -o /usr/local/bin/tutor

      # give permission to tutor user
      sudo chmod 0755 /usr/local/bin/tutor

      # take input from user
      echo "Enter LMS_HOST Name:"
      read LMS_HOST
      echo "Enter Course Email:"
      read COURSE_EMAIL
    #   echo "Enter SMTP HOST:"
    #   read SMTP_HOST
      echo "Enter SMTP USERNAME:"
      read SMTP_USERNAME
      echo "Enter SMTP PASSWORD:"
      read SMTP_PASSWORD
    #   echo "Enter CONTACT EMAIL:"
    #   read CONTACT_EMAIL

      # tutor plugins
      tutor plugins enable forum && tutor config save

      # tutor config for portel
      
      tutor config save --set CMS_HOST="studio.$LMS_HOST.rcmoocs.in"  \
      --set LMS_HOST="$LMS_HOST.rcmoocs.in"\
      --set ENABLE_HTTPS=true \
      --set SMTP_HOST="email-smtp.ap-south-1.amazonaws.com" \
      --set SMTP_PORT=587 \
      --set SMTP_USE_TLS=true \
      --set SMTP_USERNAME="$SMTP_USERNAME" \
      --set SMTP_PASSWORD="$SMTP_PASSWORD" \
      --set CONTACT_EMAIL="tlc@ramanujancollege.ac.in" \

      # Get the path to the lms.env.json file
      # lms_env_file="$(tutor config printroot)/env/apps/openedx/config/lms.env.json"
      
      # Add Course Email
      jq --arg COURSE_EMAIL "$COURSE_EMAIL" '. | . + { "COURSE_EMAIL": $COURSE_EMAIL }' "$lms_env_file" > tmp.json && mv tmp.json "$lms_env_file"

      #tutor build 
      tutor local start -d

      # tutor migrate
      tutor local init 

      # update lms and lms worker docker image
      YAML_FILE=".local/share/tutor/env/local/docker-compose.yml"
      NEW_IMAGE="7503444967/maple-edx-server:volume-final.1.5-without-pmmmt"

      # Use sed to replace the image line for the 'lms' service
      sed -i "/^ *lms:/,/^ *[^ ]/ s|image: docker.io/overhangio/openedx:13.1.5|image: $NEW_IMAGE|" "$YAML_FILE"  
      sed -i "/^ *lms-worker:/,/^ *[^ ]/ s|image: docker.io/overhangio/openedx:13.1.5|image: $NEW_IMAGE|" "$YAML_FILE" 

      # tutor settheme 
      tutor local settheme edx-reborn-indigo 

      # tutor restart
      tutor local stop && tutor local start -d


      echo "Work complete your $LMS_HOST portal is ready"
      echo "Thank you !!"

  fi
