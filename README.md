# Teabag
A WoW addon that displays your bag contents grouped by item type

# Install
Just ```git clone https://github.com/r1sc/Teabag.git``` in your Interface\AddOns folder.

# Usage
To toggle Teabag, assign a keybinding in the default options UI.  
It's also possible to toggle it with ```/script ToggleTeabag()``` if you would like to use a macro instead.

You can set the variable ```TEABAG_COLUMNS``` to whatever number of item columns you would like Teabag to render. Default is 6.  
For example: ```/script TEABAG_COLUMNS=4``` will display a more compact UI. The variable is saved between sessions.
