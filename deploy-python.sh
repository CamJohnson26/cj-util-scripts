#!/bin/bash

# Check if at least one argument (GitHub repo URL) is provided
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <github_repo_url> [args_for_main.py]"
    exit 1
fi

# Variables
GITHUB_REPO_URL=$1
REPO_NAME=$(basename -s .git $GITHUB_REPO_URL)
REMOTE_DIR="$HOME/worker-jobs/$REPO_NAME"
VENV_DIR="myenv"
PYTHON_SCRIPT="main.py"
shift  # Shift the arguments to remove the first one (GitHub repo URL)
SCRIPT_ARGS="$@"  # Remaining arguments to pass to the Python script

# Update and upgrade the server
echo "Updating and upgrading the server..."
sudo apt update && sudo apt upgrade -y

# Install Python, pip, virtualenv, and git
echo "Installing Python, pip, virtualenv, and git..."
sudo apt install python3 python3-pip python3-venv git -y

# Create base directory if it doesn't exist
mkdir -p $HOME/worker-jobs

# Clone the GitHub repository if it doesn't exist, or pull the latest changes if it does
if [ -d "$REMOTE_DIR" ]; then
    echo "Pulling the latest changes from the GitHub repository..."
    cd $REMOTE_DIR
    git pull
else
    echo "Cloning the GitHub repository..."
    git clone $GITHUB_REPO_URL $REMOTE_DIR
    cd $REMOTE_DIR
    
    # Prompt user to create .env file
    echo "Please create a .env file in the repository directory: $REMOTE_DIR"
    read -p "Press Enter to continue after creating the .env file..."
fi

# Set up the virtual environment and install dependencies
echo "Setting up the virtual environment and installing dependencies..."
python3 -m venv $VENV_DIR
source $VENV_DIR/bin/activate

# Ref: https://stackoverflow.com/questions/69919970/no-module-named-distutils-but-distutils-installed/76691103#76691103
pip3 install setuptools

if [ -f "requirements.txt" ]; then
    echo "Installing dependencies from requirements.txt..."
    pip install -r requirements.txt
fi

# Run the Python script with the provided arguments
echo "Running the Python script..."
nohup python3 -u $PYTHON_SCRIPT $SCRIPT_ARGS > nohup.out 2>&1 &

# Deactivate the virtual environment
deactivate

echo "Script execution completed."