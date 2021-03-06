﻿local L = LibStub("AceLocale-3.0"):NewLocale("StealPurgeDispel", "enUS" ,true)



L["%s loaded."] = true
L[": "] = true
L["None"] = true
L["Ascending"] = true
L["Descending"] = true
L["errorMacro"] = "Steal, Purge & Dispel cannot create custom dispel macro. Please delete one macro in your character specific macro pannel and reload your UI (/reload)."
L["SP&D config"] = true
L["Toggles SP&D configuration panel."] = true
L["Welcome in SP&D options."] = true
L["Configuration mode"] = true
L["Enables SP&D configuration mode."] = true
L["Reset"] = true
L["Resets all settings."] = true
L["This will reset all Steal, Purge & Dispel settings. Are you sure?"] = true
L["Steal, Purge & Dispel has been reset."] = true
L["General"] = true
L["General addon settings."] = true
L["Dispel me!!!"] = true
L["target"] = "Target"
L["focus"] = "Focus"
L["Text font"] = true
L["Text outline"] = true
L["Outline"] = true
L["Thickoutline"] = true
L["Text shadow"] = true
L["Enable background"] = true
L["Background texture"] = true
L["Enable border"] = true
L["Border texture"] = true
L["Texture"] = true
L["Title prefix"] = true
L["Displays unit type before unit name."] = true
L["Prefix color"] = true
L["Sounds"] = true
L["Enable"] = true
L["Play a sound when your target has a dispellable aura."] = true
L["Play a sound when your focus has a dispellable aura."] = true
L["Sorting"] = true
L["Ascending"] = true
L["Descending"] = true
L["Decimal"] = true
L["Decimal precision of timers once time is less than 10 sec."] = true
L["No decimal"] = true
L["1 decimal"] = true
L["2 decimals"] = true
L["Welcome message"] = true
L["Refresh speed"] = true
L["Don't touch it or you'll blow up the whole thing!"] = true
L["Enables focus frame."] = true
L["Target aura number"] = true
L["Maximum number of aura to show on the target."] = true
L["Focus aura number"] = true
L["Maximum number of aura to show on the focus."] = true
L["Position"] = true
L["Horizontal position"] = true
L["Vertical position"] = true
L["Anchorage point"] = true
L["Top"] = true
L["Bottom"] = true
L["Strata"] = true
L["Low"] = true
L["Medium"] = true
L["High"] = true
L["Background"] = true
L["Background color"] = true
L["Border color"] = true
L["Border thickness"] = true
L["Inset"] = true
L["Bars"] = true
L["Bar width"] = true
L["Bar height"] = true
L["Horizontal padding"] = true
L["Vertical padding"] = true
L["Reverse"] = true
L["Reverses the direction of the bar."] = true
L["Anchor"] = true
L["Bar anchorage"] = true 
L["Left"] = true
L["Right"] = true
L["Remaining time"] = true
L["Displays aura remaining time on the bar."] = true
L["Icon padding"] = true
L["Bar color"] = true
L["Background shade"] = true
L["Sets up the light/dark balance of the bar background."] = true
L["Enable icon"] = true
L["Background opacity"] = true
L["Title"] = true
L["Title height"] = true
L["Title padding"] = true
L["Title opacity"] = true
L["Texts"] = true
L["Size"] = true
L["title"] = "Title"
L["barMain"] = "Aura name"
L["barTime"] = "Aura remaining time"
L["barCount"] = "Aura stack"
L["Text alignment"] = true
L["Center"] = true
L["Horizontal offset"] = true
L["Vertical offset"] = true
L["Text color"] = true
L["Macro"] = true
L["Dispel macro settings."] = true
L["Macro name"] = true
L["Enter macro name."] = true
L["Left button"] = true
L["Right button"] = true
L["Middle button"] = true
L["Button 4"] = true
L["Button 5"] = true
L["Shift"] = true
L["Alt"] = true
L["Ctrl"] = true
L["Target mouse button"] = true
L["Selects the mouse button associated with target."] = true
L["Target modifier key"] = true
L["Selects the modifier key associated with target."] = true
L["Focus mouse button"] = true
L["Selects the mouse button associated with focus."] = true
L["Focus modifier key"] = true
L["Selects the modifier key associated with focus."] = true
L["No modifier"] = true
L["Advanced editing"] = true
L["Edit box"] = true
L["Buttons"] = true
L["Dispel button settings"] = true
L["Button size"] = true
L["MouseOver highlight"] = true
L["Sets button transparency when an aura can be dispelled."] = true
L["Active button alpha"] = true
L["Sets button transparency when no aura can be dispelled."] = true
L["Inactive button alpha"] = true
L["Button texture"] = true
L["_blue"] = "Blue"
L["_green"] = "Green"
L["_green_light"] = "Green light"
L["_violet"] = "Violet"
L["_red"] = "Red"
L["_orange"] = "Orange"
L["Custom Lists"] = true
L["User white and black lists."] = true
L["Please enable \"Config mode\" and target and/or focus a player or a npc in order to make the dispel button visible."] = true
L["wl"] = "White list"
L["bl"] = "Black list"
L["wlDescInput"] = "Use this box to add a custom aura not detected by SP&D:"
L["blDescInput"] = "Use this box to hide an aura detected by SP&D:"
L["Add a spell"] = true
L["This is not a valid spell ID."] = true
L["This is not a valid input."] = true
L["%s has been added to the %s."] = true
L["Auras management:"] = true
L["Remove"] = true
L["This will remove %s from your %s. Are you sure?"] = true
L["This aura is already registered."] = true
L["Toggle to enable/disable this aura."] = true
L["Remove completly this aura from SP&D."] = true
L["inputBox"] = "You can use spell ID or spell name ; you must type the exact spell wording in the later case. Only cancellable auras are considered."
L["%s has been removed from the %s."] = true
L["Hide short auras"] = true
L["Toggle to autohide the frame if only auras with a short remaining duration are present on the unit."] = true
L["Remaining duration below:"] = true
L["Enable focus"] = true
L["Dispel frames"] = true
L["Sounds"] = true
L["Enhance immunity"] = true
L["Shows immunity spells in a different color."] = true
L["Select color"] = true
L["Miscellaneous settings"] = true
L["Priest and warrior specific"] = true
L["Timer bar settings"] = true
L["Layout"] = true
L["Layout settings."] = true
L["Simple settings"] = true
L["Untick to finely tune text settings."] = true
L["Target specific settings:"] = true
L["Focus specific settings:"] = true
L["Focus like target"] = true
L["Untick to access to focus settings."] = true
L["Border"] = true
L["Percentage of the frame height."] = true
L["Bar display"] = true
L["Choose one of the three types of display for the timer bar."] = true
L["Name, time"] = true
L["Time, name"] = true
L["Name only"] = true
L["Extra size"] = true
L["Increases the size of the edge of the frame."] = true
L["Button edge size"] = true
L["SP&D: "] = true
L["Configuration available only when your character knows a dispel spell."] = true
