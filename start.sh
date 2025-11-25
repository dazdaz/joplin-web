#!/bin/bash

# Configuration
PROJECT_NAME="flutter_app"
PORT=8081
PID_FILE=".joplin_web.pid"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Navigation Logic
# Check if we are inside the project or next to it
if [ -f "pubspec.yaml" ]; then
    PROJECT_ROOT="."
elif [ -d "$PROJECT_NAME" ]; then
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
            rm "$PID_FILE"
        fi
    fi

    if lsof -i :$PORT > /dev/null 2>&1; then
        echo -e "${RED}Error: Port $PORT is already in use.${NC}"
        exit 1
    fi

    cd "$PROJECT_ROOT"
    
    # Force clean build if requested or if build missing
    if [ "$1" == "--clean" ] || [ "$1" == "clean" ] || [ ! -d "build/web" ]; then
        echo -e "${YELLOW}Building Flutter Web project (Clean Build)...${NC}"
        flutter clean
        flutter pub get
        flutter build web --release
    fi

    echo -e "${GREEN}Starting local server on port $PORT...${NC}"
    
    if ! cd build/web; then
        echo -e "${RED}Error: Could not enter build/web directory. Current dir: $(pwd)${NC}"
        exit 1
    fi
    echo -e "Serving from: $(pwd)"
    
    nohup python3 -m http.server $PORT > /dev/null 2>&1 & 
    SERVER_PID=$!
    
    cd ../../..
    echo $SERVER_PID > "$PID_FILE"
    
    echo -e "${GREEN}Success! Joplin Web is running.${NC}"
    echo -e "🌐 Access it here: ${GREEN}http://localhost:$PORT${NC}"
    echo -e "   (Run './start.sh stop' to close it)"
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

# Function to run debug mode with hot reload (Flutter debug)
run_flutter_debug() {
    echo -e "${YELLOW}Starting Flutter Debug Mode with Hot Reload...${NC}"
    echo -e "This provides:"
    echo -e "  - Hot reload (press 'r' in terminal)"
    echo -e "  - Full debug logging in browser console"
    echo -e "  - Source maps for debugging"
    echo ""
    cd "$PROJECT_ROOT"
    flutter run -d chrome --web-renderer html
}

# Function to run debug server (production build with debug info)
run_debug_server() {
    echo -e "${YELLOW}Building Flutter Web project with Debug Info...${NC}"
    
    # Stop any existing server
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null 2>&1; then
            kill $PID
            rm "$PID_FILE"
        fi
    fi

    if lsof -i :$PORT > /dev/null 2>&1; then
        echo -e "${RED}Error: Port $PORT is already in use.${NC}"
        exit 1
    fi

    cd "$PROJECT_ROOT"
    
    # Clean and build with source maps
    flutter clean
    flutter pub get
    
    # Build with profile mode for better debugging
    echo -e "${YELLOW}Building with debug source maps...${NC}"
    flutter build web --profile --source-maps
    
    echo -e "${GREEN}Starting debug server on port $PORT...${NC}"
    
    if ! cd build/web; then
        echo -e "${RED}Error: Could not enter build/web directory.${NC}"
        exit 1
    fi
    
    echo -e "Serving from: $(pwd)"
    
    # Run Python server with verbose logging
    echo -e "${YELLOW}Server logging enabled. Press Ctrl+C to stop.${NC}"
    echo -e "============================================"
    python3 -m http.server $PORT
}

# Function to show status
show_status() {
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p $PID > /dev/null; then
            echo -e "${GREEN}Joplin Web is running (PID: $PID)${NC}"
            echo -e "URL: http://localhost:$PORT"
        else
            echo -e "${YELLOW}PID file exists but process not running. Cleaning up.${NC}"
            rm "$PID_FILE"
        fi
    else
        echo -e "${YELLOW}Joplin Web is not running.${NC}"
    fi
}

# Show help
show_help() {
    echo -e "${GREEN}Joplin Web - Start Script${NC}"
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start [clean]  - Build (if needed) and serve the app in the background"
    echo "  stop           - Stop the background server"
    echo "  debug          - Run with Flutter hot reload in Chrome (development mode)"
    echo "  debug-server   - Build with source maps and run server with logging"
    echo "  status         - Check if the server is running"
    echo "  help           - Show this help message"
    echo ""
    echo "Options:"
    echo "  clean          - Force a clean rebuild before starting"
    echo ""
    echo "Debug Commands:"
    echo "  $0 debug          # Best for development - hot reload in Chrome"
    echo "  $0 debug-server   # Debug build served with logging"
    echo ""
    echo "Examples:"
    echo "  $0 start           # Start the server"
    echo "  $0 start clean     # Clean build and start"
    echo "  $0 stop            # Stop the server"
    echo "  $0 debug           # Run in debug mode with hot reload"
    echo "  $0 debug-server    # Run debug build with server logging"
}

# Main Argument Parsing
case "$1" in
    start|--start)
        start_server "$2"
        ;;
    stop|--stop)
        stop_server
        ;;
    debug|--debug)
        run_flutter_debug
        ;;
    debug-server|--debug-server)
        run_debug_server
        ;;
    status|--status)
        show_status
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        show_help
        exit 1
        ;;
esac
