#!/bin/bash
set -e

PROJECT_NAME="joplin_web_shell"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}==============================================${NC}"
echo -e "${GREEN}   Joplin Web Shell Generator                 ${NC}"
echo -e "${GREEN}==============================================${NC}"

# 1. Get Data Source
echo ""
echo -e "${YELLOW}Enter the path to your Joplin JSON Export directory:${NC}"
read -e -p "Path: " EXPORT_PATH
# Remove trailing slash
EXPORT_PATH=${EXPORT_PATH%/}

if [ ! -d "$EXPORT_PATH" ]; then
    echo -e "${RED}Error: Directory '$EXPORT_PATH' does not exist.${NC}"
    exit 1
fi

# 2. Create Project
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${YELLOW}Removing old project folder...${NC}"
    rm -rf "$PROJECT_NAME"
fi

echo -e "${GREEN}Creating Flutter Web project...${NC}"
flutter create --platforms web "$PROJECT_NAME" --empty > /dev/null
cd "$PROJECT_NAME"

# 3. Add Dependencies
echo -e "${GREEN}Adding dependencies...${NC}"
flutter pub add provider flutter_markdown intl universal_html > /dev/null

# 4. Process Data & Assets
echo -e "${GREEN}Processing Joplin data and attachments...${NC}"
mkdir -p assets/resources

# Copy resources (images) from export to assets
if [ -d "$EXPORT_PATH/resources" ]; then
    echo "Copying resource files..."
    cp -r "$EXPORT_PATH/resources"/* assets/resources/ 2>/dev/null || true
fi

# Python script to merge JSON files into one db.json
python3 -c "
import os
import json
import sys

export_path = '$EXPORT_PATH'
db = {'notebooks': [], 'notes': []}
files_processed = 0

for root, dirs, files in os.walk(export_path):
    for name in files:
        if not name.endswith('.json'): continue
        
        try:
            with open(os.path.join(root, name), 'r', encoding='utf-8') as f:
                data = json.load(f)
                # Type 1: Note, Type 2: Notebook
                if data.get('type_') == 2:
                    db['notebooks'].append({
                        'id': data.get('id'),
                        'title': data.get('title', 'Untitled'),
                        'parent_id': data.get('parent_id', '')
                    })
                elif data.get('type_') == 1:
                    db['notes'].append({
                        'id': data.get('id'),
                        'parent_id': data.get('parent_id'),
                        'title': data.get('title', 'Untitled'),
                        'body': data.get('body', ''),
                        'updated_time': data.get('user_updated_time') or data.get('updated_time')
                    })
                files_processed += 1
        except Exception as e:
            print(f'Error reading {name}: {e}')

# Sort for consistency
db['notebooks'].sort(key=lambda x: x['title'].lower())
db['notes'].sort(key=lambda x: x['updated_time'], reverse=True)

with open('assets/db.json', 'w', encoding='utf-8') as f:
    json.dump(db, f)

print(f'Processed {files_processed} files.')
"

# 5. Update pubspec.yaml to include assets
python3 -c "
lines = open('pubspec.yaml').readlines()
with open('pubspec.yaml', 'w') as f:
    assets_active = False
    for line in lines:
        f.write(line)
        if 'flutter:' in line:
            assets_active = True
    if assets_active:
        f.write('  assets:\n    - assets/db.json\n    - assets/resources/\n')
"

echo -e "${GREEN}Setup complete! Now copy the Dart files into lib/ folder.${NC}"
