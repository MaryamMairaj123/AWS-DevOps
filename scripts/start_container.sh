#!/bin/bash
set -e

# Pull the Docker image from Docker Hub
#docker pull maryammairaj/python-flask-app-service:latest
docker pull maryammairaj/python-flask-app-service

# Run the Docker image as a container
docker run -d -p 5000:5000 maryammairaj/python-flask-app-service


