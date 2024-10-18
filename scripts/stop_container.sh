#!/bin/bash
set -e

# Stop the running container (if any)
echo "Hi"
# #!/bin/bash
# set -e

# Stop the running container (if any)
container_name="priceless_varahamihira"

if [ $(docker ps -q -f name=$container_name) ]; then
    echo "Stopping the container: $container_name"
    docker stop $container_name
    docker rm $container_name
else
    echo "No running container found with name: $container_name"
fi


