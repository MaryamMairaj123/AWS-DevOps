# #!/bin/bash
# set -e

# Stop the running container (if any)
#echo "Hi"
# #!/bin/bash
# set -e

# Stop the running container (if any)
#container_name="priceless_varahamihira"

#if [ $(docker ps -q -f name=$container_name) ]; then
 #   echo "Stopping the container: $container_name"
  #  docker stop $container_name
   # docker rm $container_name
#else
 #   echo "No running container found with name: $container_name"
#fi

#!/bin/bash
set -e

# Specify the new version
new_version="v1.1"
container_name="flask-app-${new_version//./-}"

# Stop and remove the old container if it exists
if [ $(docker ps -q -f name=flask-app) ]; then
    echo "Stopping and removing the old container: flask-app"
    docker stop flask-app
    docker rm flask-app
fi

# Pull the new Docker image version
docker pull maryammairaj/python-flask-app-service:$new_version

# Run the new container
docker run -d -p 5000:5000 --name flask-app maryammairaj/python-flask-app-service:$new_version



