# QB Admin Duty System

A unique admin duty system for QBCore that allows staff members to toggle duty status with custom models and floating nameplates.

## Features

- **Custom Admin Models**: Changes player model to admin-specific character when on duty
- **Floating Nameplates**: Displays staff name and title above their head with custom colors
- **Permission System**: Dual permission checking (license-based and ACE permissions)
- **Appearance Preservation**: Saves and restores player appearance using illenium-appearance or fallback methods
- **Server-wide Sync**: All players see which admins are currently on duty
- **Customizable Titles**: Pre-configured staff titles with unique colors

## Installation

1. Add this resource to your `resources` directory
2. Ensure the resource starts after `qb-core` and `illenium-appearance` (if used)
3. Add the following to your `server.cfg`:
4. ensure void-adminmenu


## Configuration

### Staff Licenses and Titles

Edit the following tables in `server.lua` to add your staff members:

```lua
local licenseToName = {
 ['license:your_license_here'] = 'StaffMemberName'
}

local licenseToTitle = {
 ['license:your_license_here'] = 'Staff Title'
}

local titleColors = {
 ['Staff Title'] = {R, G, B, A}
}
