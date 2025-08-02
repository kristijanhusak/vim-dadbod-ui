# Architecture Overview

This document outlines the architecture and design decisions for the vim-dadbod-ui Lua rewrite.

## Design Goals

1. **Performance**: Native Lua implementation for better performance
2. **Maintainability**: Clean, modular architecture with clear separation of concerns
3. **Extensibility**: Easy to extend and customize
4. **Backwards Compatibility**: Seamless migration from Vimscript version
5. **Modern Neovim Integration**: Leverage modern Neovim Lua APIs

## Module Structure

```
lua/db_ui/
├── init.lua              # Main entry point and public API
├── config.lua            # Configuration management
├── utils.lua             # Utility functions
├── notifications.lua     # Notification system
├── drawer.lua            # UI drawer/tree component
├── connections.lua       # Connection management
├── query.lua             # Query execution and buffer management
├── schemas.lua           # Database schema handling (future)
├── table_helpers.lua     # Table helper queries (future)
└── dbout.lua             # Query result handling (future)

plugin/
└── db_ui.lua             # Plugin initialization and commands

doc/
├── db_ui_lua.txt         # Vim help documentation
└── ARCHITECTURE.md       # This file

README_LUA.md             # User documentation
MIGRATION_GUIDE.md        # Migration guide
init.lua                  # User setup entry point
```

## Core Components

### 1. Configuration System (`config.lua`)

**Responsibilities:**
- Manage all plugin configuration
- Provide backwards compatibility with Vimscript global variables
- Handle icon configuration and nerd font support
- Validate configuration options

**Design:**
- Single setup function that merges user config with defaults
- Support for both new Lua config and legacy global variables
- Icon system with support for custom and nerd font icons

### 2. Main DBUI Class (`init.lua`)

**Responsibilities:**
- Core plugin state management
- Database connection discovery and management
- Integration with vim-dadbod
- Public API interface

**Design:**
- Singleton pattern for main DBUI instance
- Lazy initialization for better startup performance
- Clear separation between public API and internal implementation

### 3. Drawer/UI Component (`drawer.lua`)

**Responsibilities:**
- Tree-style UI rendering
- User interaction handling (navigation, selection)
- Buffer management for DBUI drawer
- Integration with query component

**Design:**
- Object-oriented design with clear state management
- Event-driven interaction model
- Pluggable key mapping system

### 4. Connection Management (`connections.lua`)

**Responsibilities:**
- Add/edit/delete database connections
- Import/export connection configurations
- Connection validation and testing
- File-based persistence

**Design:**
- CRUD operations for connections
- JSON-based storage format
- Support for multiple connection sources (env, dotenv, g:dbs, file)

### 5. Query Execution (`query.lua`)

**Responsibilities:**
- SQL buffer creation and management
- Query execution coordination with vim-dadbod
- Bind parameter handling
- Query saving and loading

**Design:**
- Buffer lifecycle management
- Template-based query generation
- Async query support integration
- Visual selection and bind parameter support

### 6. Notification System (`notifications.lua`)

**Responsibilities:**
- User feedback and status messages
- Integration with nvim-notify
- Fallback to vim echo functions
- Progress indication for long operations

**Design:**
- Abstracted notification interface
- Graceful degradation when nvim-notify unavailable
- Configurable notification levels and styling

### 7. Utilities (`utils.lua`)

**Responsibilities:**
- Common utility functions
- File I/O operations (JSON handling)
- String manipulation helpers
- Buffer and window utilities

**Design:**
- Pure functions where possible
- Consistent error handling
- Cross-platform compatibility

## Data Flow

```
User Action
    ↓
Command/Keymap
    ↓
Main API (init.lua)
    ↓
Drawer Component
    ↓
Connection/Query Components
    ↓
vim-dadbod Integration
    ↓
Database Operation
    ↓
Result Processing
    ↓
UI Update
```

## State Management

### Global State
- Single DBUI instance with all plugin state
- Database connections and metadata
- UI state (expanded/collapsed nodes)
- Query history and saved queries

### Buffer State
- Per-buffer variables for database association
- Query buffer metadata
- Temporary file tracking

### Configuration State
- Immutable after setup() call
- Global configuration accessible to all modules
- Environment variable integration

## Error Handling Strategy

1. **Graceful Degradation**: Continue working with reduced functionality
2. **User-Friendly Messages**: Clear error messages via notification system
3. **Debug Mode**: Detailed logging for troubleshooting
4. **Validation**: Early validation of user input and configuration

## Integration Points

### vim-dadbod Integration
- Connection establishment via `db#connect()`
- Query execution via `DB` command
- Schema discovery via adapter functions
- URL parsing and validation

### Neovim API Integration
- Modern Lua APIs for buffers, windows, and autocommands
- Keymap API for user interactions
- File system operations via vim.fn
- User input via vim.fn.input

### nvim-notify Integration
- Optional dependency with graceful fallback
- Enhanced notification styling and positioning
- Progress indicators for long operations

## Performance Considerations

### Startup Performance
- Lazy loading of modules
- Deferred initialization until first use
- Minimal global variable setup

### Runtime Performance
- Efficient tree rendering with minimal DOM manipulation
- Cached database metadata
- Incremental UI updates
- Async operation support

### Memory Management
- Clean buffer lifecycle management
- Proper autocommand cleanup
- Garbage collection friendly patterns

## Security Considerations

### Connection String Handling
- Secure storage of connection information
- Environment variable support for sensitive data
- No logging of connection strings in debug mode

### File System Access
- Proper path validation and sanitization
- Respect for user-defined save locations
- Safe temporary file handling

## Testing Strategy

### Unit Tests
- Individual module testing
- Configuration validation
- Utility function testing

### Integration Tests
- End-to-end workflow testing
- Database connection testing
- UI interaction testing

### Compatibility Tests
- Multiple Neovim versions
- Different database types
- Various configuration scenarios

## Future Extensibility

### Plugin System
- Hook system for custom functionality
- Event system for third-party integration
- Modular architecture for feature additions

### Database Support
- Adapter pattern for new database types
- Custom schema handlers
- Extensible table helpers

### UI Customization
- Themeable icon system
- Custom rendering functions
- Pluggable UI components

## Migration Strategy

### Backwards Compatibility
- Support for existing global variables
- Compatible command names and behavior
- Preserved key mappings and workflows

### Migration Tools
- Configuration migration utilities
- Connection import/export
- Automated testing for compatibility

### Documentation
- Comprehensive migration guide
- Side-by-side configuration examples
- Troubleshooting guide for common issues

## Code Quality Standards

### Lua Style Guide
- Consistent naming conventions
- Clear module boundaries
- Documented public APIs

### Error Handling
- Consistent error propagation
- User-friendly error messages
- Proper logging and debugging

### Documentation
- Inline code documentation
- API documentation
- Architecture documentation (this file)

## Development Workflow

### Setup
1. Clone repository
2. Install dependencies (vim-dadbod, optional nvim-notify)
3. Configure test databases
4. Run test suite

### Testing
- Unit tests for individual modules
- Integration tests for workflows
- Manual testing with real databases

### Release Process
- Version tagging
- Documentation updates
- Migration guide updates
- Compatibility testing 