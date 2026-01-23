#!/bin/bash

# This script starts the Vagrant environment with the host machine's IP address
HOST_IP=$(hostname -I | cut -d " " -f1) vagrant up