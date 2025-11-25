# Joplin Web

A web-based note-taking application inspired and compatible by [Joplin](https://joplinapp.org/), built with Flutter.

## Features

- **Three-pane layout**: Notebooks sidebar, notes list, and note editor
- **Markdown editing**: Full markdown support with live preview
- **Markdown toolbar**: Quick formatting buttons for bold, italic, headers, lists, etc.
- **Hierarchical notebooks**: Organize notes in nested notebook structures
- **Expand/Collapse notebooks**: Double-click to toggle notebook children visibility
- **JEX Import**: Import Joplin Export (.jex) archives with full metadata support
- **Markdown Import/Export**: Import and export individual markdown files
- **Search**: Filter notes by title and content
- **Debug logging**: Built-in import log viewer for troubleshooting

<img width="1512" height="771" alt="Screenshot 2025-11-25 at 20 54 51" src="https://github.com/user-attachments/assets/326d6e9a-07e1-44f9-b69f-46515016d54c" />

## Project Structure

```
joplin-web/
├── flutter_app/           # Flutter web application
│   ├── lib/
│   │   ├── main.dart      # App entry point with menu bar
│   │   ├── models.dart    # Note and Notebook data models
│   │   ├── screens.dart   # UI components (Sidebar, NotesList, EditorPane)
│   │   └── service.dart   # Business logic and JEX import
│   ├── assets/
│   │   └── db.json        # Sample data
│   └── web/
│       └── index.html     # Web entry point
├── start.sh               # Server management script
├── README.md              # This file
└── .gitignore             # Git ignore rules
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0 or later)
- A modern web browser

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd joplin-web
```

2. Install dependencies:
```bash
cd flutter_app
flutter pub get
```

3. Build and run:
```bash
cd ..
./start.sh start
```

4. Open http://localhost:8081 in your browser

## Usage

### Server Management

```bash
# Start the server (builds if needed)
./start.sh start

# Start with a clean rebuild
./start.sh start clean

# Stop the server
./start.sh stop

# Check server status
./start.sh status

# Run in debug mode with hot reload (development)
./start.sh debug

# Run debug build with server logging
./start.sh debug-server
```

### Importing Notes

1. **Import JEX file**: File → Import Joplin Export (.jex)
2. **Import Markdown**: File → Import Markdown (.md)

### Exporting Notes

1. Select a note
2. File → Export Note as Markdown

### Keyboard Shortcuts (in editor)

The markdown toolbar provides quick formatting:
- **Bold**: Click bold button or wrap text in `**`
- **Italic**: Click italic button or wrap text in `*`
- **Strikethrough**: Wrap text in `~~`
- **Headers**: Start line with `#`
- **Lists**: Start line with `-` or `1.`
- **Tasks**: Start line with `- [ ]`
- **Links**: Use `[text](url)` format
- **Code**: Wrap in backticks

### Debugging

If you encounter issues importing JEX files:
1. Help → View Import Log
2. Help → Download Debug Log

## Technical Details

### JEX File Format

JEX files are uncompressed TAR archives containing:
- `.md` files with note/notebook content
- Metadata embedded at the end of each file
- `type_: 1` = Note, `type_: 2` = Notebook

### Supported Metadata Fields

The app recognizes all standard Joplin metadata fields:
- `id`, `parent_id`, `title`, `type_`
- `created_time`, `updated_time`, `user_created_time`, `user_updated_time`
- `is_conflict`, `is_todo`, `todo_due`, `todo_completed`
- `latitude`, `longitude`, `altitude`
- `author`, `source_url`, `source`, `source_application`
- `markup_language`, `is_shared`, `share_id`, `order`
- `encryption_cipher_text`, `encryption_applied`, `master_key_id`
- `icon`, `deleted_time`, `user_data`, `conflict_original_id`

## License

This project is for educational purposes.

## Acknowledgments

- [Joplin](https://joplinapp.org/) - The original note-taking application
- [Flutter](https://flutter.dev/) - UI framework