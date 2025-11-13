#!/bin/bash

# Configuration
PROJECT_NAME="joplin_web_clone"
PORT=8080
PID_FILE=".joplin_web.pid"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Navigation Logic
# Check if we are inside the project or next to it
if [ -f "pubspec.yaml" ]; then
    # We are inside the project
    PROJECT_ROOT="."
elif [ -d "$PROJECT_NAME" ]; then
    # We are next to the project
    PROJECT_ROOT="./$PROJECT_NAME"
else
    echo -e "${RED}Error: Could not find the Flutter project '$PROJECT_NAME'.${NC}"
    echo "Please ensure you are in the directory containing the project."
    exit 1
fi

# Function to start the production server
start_server() {
    if [ -f "$PID_FILE" ]; then
        if ps -p $(cat "$PID_FILE") > /dev/null; then
            echo -e "${YELLOW}App is already running (PID: $(cat $PID_FILE)).${NC}"
            echo -e "Open: http://localhost:$PORT"
            exit 0
        else
            # Stale PID file
            rm "$PID_FILE"
        fi
    fi

    cd "$PROJECT_ROOT"
    
    # Check if build exists, if not, build it
    if [ ! -d "build/web" ]; then
        echo -e "${YELLOW}Build not found. Building Flutter Web project...${NC}"
        flutter build web --release
    fi

    echo -e "${GREEN}Starting local server on port $PORT...${NC}"
    
    # Enter build directory to serve files
    cd build/web
    
    # Start Python server in background, suppress output, save PID
    nohup python3 -m http.server $PORT > /dev/null 2>&1 & 
    SERVER_PID=$!
    
    # Save PID to file (relative to where the script started)
    cd ../../.. # Go back to original location
    echo $SERVER_PID > "$PID_FILE"
    
    echo -e "${GREEN}Success! Joplin Web is running.${NC}"
    echo -e "üëâ Access it here: ${GREEN}http://localhost:$PORT${NC}"
    echo -e "   (Run './start.sh --stop' to close it)"
}

# Function to stop the server
stop_server() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null; then
            kill $PID
            echo -e "${GREEN}Stopped Joplin Web server (PID: $PID).${NC}"
        else
            echo -e "${YELLOW}Process $PID not found, but PID file existed. Cleaning up.${NC}"
        fi
        rm "$PID_FILE"
    else
        echo -e "${RED}No active server found (PID file missing).${NC}"
    fi
}

# Function to run debug mode
debug_app() {
    echo -e "${YELLOW}Entering Debug Mode (Hot Reload enabled)...${NC}"
    cd "$PROJECT_ROOT"
    flutter run -d chrome
}

# Main Argument Parsing
case "$1" in
    --start)
        start_server
        ;;
    --stop)
        stop_server
        ;;
    --debug)
        debug_app
        ;;
    *)
        echo -e "${RED}Usage: $0 {--start|--stop|--debug}${NC}"
        echo "  --start  : Build (if needed) and serve the app in the background."
        echo "  --debug  : Run the app in Chrome with Hot Reload (occupies terminal)."
        echo "  --stop   : Stop the background server."
        exit 1
        ;;
esac
