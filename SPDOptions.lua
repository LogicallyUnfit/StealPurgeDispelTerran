if StealPurgeDispel == nil then
	return
end

-- library initialization
local SPD = StealPurgeDispel
local L = LibStub("AceLocale-3.0"):GetLocale("StealPurgeDispel", true)
local LSM = LibStub("LibSharedMedia-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

-- cache
local pairs, ipairs, type, tonumber, tostring, print, tinsert, tremove, wipe = pairs, ipairs, type, tonumber, tostring, print, tinsert, tremove, wipe
local strfind, strsub, floor, ceil, format = strfind, strsub, floor, ceil, format
local _

-- global table
SPD.fakeAuras = {}

-- housekeeping functions ------------------

local function GetColor(t)
	return t.r, t.g, t.b, t.a
end

local function SetColor(t, r, g, b, a)
	t.r, t.g, t.b, t.a = r, g, b, a or t.a
end

local function DeepCopy(src)
	local res = {}
    for k, v in pairs(src) do
        if type(v) == "table" then
            v = DeepCopy(v)
        end
        res[k] = v
    end
    return res
end

local function IsAvailable()
	return SPD.inCombat
end

-- This function walks trough a "maze" table following the path provided by the map table.
-- Read: the value at the end of the path is returned by the function.
-- Write: the new value must be passed to the newValue parameter. The value and the new value must be of the same type otherwise the newValue is discarded.
-- i is used as a recursive increment to walk through the table and shouldn't be explicitly passed to the function unless for specific purposes.
local function TableWalk(maze, map, newValue, i)
	i = i or 1
	local value

	-- debug
	if type(maze[map[i]]) ~= "boolean" then
		assert(maze[map[i]], "There is no entry in the maze table for the step number " .. i .. " with the name \"" .. map[i] .. "\".\n" )
	end

	-- recursive calls are stoped if either the end of the maze table or the end of the map table is reached
	if type(maze[map[i]]) ~= "table" or i >= #map then
		if newValue ~= nil then
			maze[map[i]] = newValue
		end
		value = maze[map[i]]
	else
		value = TableWalk(maze[map[i]], map, newValue, i + 1)
	end
	return value
end

local function FormatTime(num)
	local hour = "%d h"
	local minute = "%d m"
	local seconde = "%d s"
	local fewsec = SPD.db.profile.general.bars.decimal

	if num < 10 then
		return fewsec:format(num)
	elseif num < 60 then
		return seconde:format(num)
	elseif num < 3600 then
		return minute:format(ceil(num / 60))
	else
		return hour:format(ceil(num / 3600))
	end
end

local function List(mediatype)
	local t = {}
	for k, v in pairs(LSM:List(mediatype)) do
		t[v] = v
	end
	return t
end

local function DecToHex(input)
	local b, k, output, i, d = 16, "0123456789ABCDEF", "", 0
	while input > 0 do
		input, d = math.floor(input / b), mod(input, b) + 1
		output = string.sub(k, d, d) .. output
		i = i + 1
	end
	return output
end

local function ColorToHex(colorTable)
	local t = DeepCopy(colorTable)
	for k, v in pairs(t) do
		t[k] = DecToHex(v * 255)
	end
	local r, g, b, a = GetColor(t)
	return "|c" .. a .. r .. g .. b
end

local function round(number, dec)
	return math.floor(number * 10^dec + 0.5) / 10^dec
end



-- Table options ----------------------------

-- fake options
function SPD:FakeOptions()
	args = {
		toggleOptions = {
			type = "execute",
			order = 1,
			name = L["SP&D config"],
			desc = L["Toggles SP&D configuration panel."],
			func = function()
				SPD:LoadConfig()
			end,
		},
	}

	return args
end

-- config if SPD has been loaded and dsipel spell is not anymore available
function SPD:NoDispelOptions()
	local args = {
		message = {
			type = "description",
			name = L["Configuration available only when your character knows a dispel spell."],
			fontSize = "medium",
		},
	}
	
	return args
end

-- real options
function SPD:Options()
	local args = {
		configMode = {
			type = "toggle",
			order = 0,
			name = L["Configuration mode"],
			desc = L["Enables SP&D configuration mode."],
			width = "double",
			get = function() return SPD.configMode end,
			set = function(info, value)	SPD:ConfigMode(value) end,
		},
		reset = {
			type = "execute",
			order = 5,
			name = L["Reset"],
			desc = L["Resets all settings."],
			confirm = true,
			confirmText = L["This will reset all Steal, Purge & Dispel settings. Are you sure?"],
			func = function()
				DeleteMacro(SPD.db.char.macro.name)
				
				for k, v in pairs(SPD.db.profile) do
					wipe(SPD.db.profile[k])
					SPD.db.profile[k] = DeepCopy(SPD.defaults.profile[k])
				end
				wipe(SPD.db.char.macro)
				SPD.db.char.macro = DeepCopy(SPD.defaults.char.macro)
				
				local unitTable = {"target", "focus"}
				for _, unit in pairs(unitTable) do
					SPD:SetMain(unit, SPD.F[unit])
					SPD:SetTitle(unit, SPD.F[unit], SPD.F[unit].title)
					SPD:SetBar(unit, SPD.F[unit])
					SPD:FetchSound(unit)

					if SPD.db.profile.dispelBtn.enabled then
						SPD:SetDispelBtn(unit)
					end
				end
					
				if SPD.db.char.macro.enabled then
					SPD:SetMacro()
				end
								
				SPD:ProfileChanged()
				print(SPD.COLOR .. L["Steal, Purge & Dispel has been reset."])
			end,
		},
		general = {
			type = "group",
			order = 10,
			name = L["General"],
			desc = L["General addon settings."],
			get = function(info) return TableWalk(SPD.db.profile, info)	end,
			set = function(info, value)
				TableWalk(SPD.db.profile, info, value)
				SPD:UpdateDisplayAndData("target", info)
				SPD:UpdateDisplayAndData("focus", info)
			end,
			args = SPD:GeneralOptions(),
		},
		layout = {
			type = "group",
			order = 20,
			name = L["Layout"],
			desc = L["Layout settings."],
			get = function(info) return TableWalk(SPD.db.profile, info)	end,
			set = function(info, value)
				TableWalk(SPD.db.profile, info, value)
				SPD:UpdateDisplayAndData("target", info)
				SPD:UpdateDisplayAndData("focus", info)
			end,
			args = SPD:LayoutOptions(),
		},
		macro = {
			type = "group",
			order = 30,
			name = L["Macro"],
			desc = L["Dispel macro settings."],
			get = function(info) return TableWalk(SPD.db.char, info)	end,
			set = function(info, value)
				-- we don't let the user to set up 2 equal values for target and focus mouse buttons or modifiers
				if info[#info] == "targetBtn" and value == SPD.db.char.macro.focusBtn then
					SPD.db.char.macro.focusBtn = SPD.db.char.macro.targetBtn
				elseif info[#info] == "targetMod" and value == SPD.db.char.macro.focusMod and value ~= "" then
					SPD.db.char.macro.focusMod = SPD.db.char.macro.targetMod
				elseif info[#info] == "focusBtn" and value == SPD.db.char.macro.targetBtn then
					SPD.db.char.macro.targetBtn = SPD.db.char.macro.focusBtn
				elseif info[#info] == "focusMod" and value == SPD.db.char.macro.targetMod and value ~= "" then
					SPD.db.char.macro.targetMod = SPD.db.char.macro.focusMod
				end
								
				-- assign to var name the old name of the macro (current name for the in game macro)
				local name
				if info[#info] == "name" then
					name = SPD.db.char.macro.name
				end
				
				TableWalk(SPD.db.char, info, value)
				
				SPD:SetMacro(name)
			end,
			args = SPD:MacroOptions(),
		},
		dispelBtn = {
			type = "group",
			order = 40,
			name = L["Buttons"],
			desc = L["Dispel button settings"],
			get = function(info) return TableWalk(SPD.db.profile, info)	end,
			set = function(info, value)
				TableWalk(SPD.db.profile, info, value)
				SPD:SetDispelBtn("target")
				SPD:SetDispelBtn("focus")
			end,
			args = SPD:BtnOptions(),
		},
		customLists = {
			type = "group",
			order = 50,
			name = L["Custom Lists"],
			desc = L["User white and black lists."],
			args = SPD:CustomListOptions(),
		},
	}

	return args
end

-- general option pannel
function SPD:GeneralOptions()
	local options = {
		frames = {
			type = "group",
			inline = true,
			order = 0,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Dispel frames"],
				},
				target = {
					type = "group",
					inline = true,
					order = 10,
					args = {
						maxAura = {
							type = "select",
							order = 0,
							name = L["Target aura number"],
							desc = L["Maximum number of aura to show on the target."],
							values = function()
								local t = {}
								for i = 1, 10 do
									t[i] = i
								end
								return t
							end,
						},
					},
				},
				focus = {
					type = "group",
					inline = true,
					order = 20,
					args = {
						enabled = {
							type = "toggle",
							order = 0,
							name = L["Enable focus"],
							desc = L["Enables focus frame."],
						},
						maxAura = {
							type = "select",
							order = 10,
							disabled = function() return not SPD.db.profile.general.frames.focus.enabled end,
							name = L["Focus aura number"],
							desc = L["Maximum number of aura to show on the focus."],
							values = function()
								local t = {}
								for i = 1, 10 do
									t[i] = i
								end
								return t
							end,
						},
					},
				},
				hideShortAuras = {
					type = "toggle",
					order = 30,
					name = L["Hide short auras"],
					desc = L["Toggle to autohide the frame if only auras with a short remaining duration are present on the unit."],
				},
				hideShortTime = {
					type = "range",
					order = 40,
					name = L["Remaining duration below:"],
					min = 2, max = 10, step = 1,
				},
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},
			},
		},
		bars = {
			type = "group",
			inline = true,
			order = 5,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Timer bar settings"],
				},
				sorting = {
					type = "select",
					order = 10,
					name = L["Sorting"],
					values = {
						[""] = L["None"],
						ascending = L["Ascending"],
						descending = L["Descending"],
					},
				},
				decimal = {
					type = "select",
					order = 20,
					name = L["Decimal"],
					desc = L["Decimal precision of timers once time is less than 10 sec."],
					values = {
						["%d s"] = L["No decimal"],
						["%.1f s"] = L["1 decimal"],
						["%.2f s"] = L["2 decimals"],
					},
				},
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},
			},
		},
		sounds = {
			type = "group",
			inline = true,
			order = 10,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Sounds"],
				},
				enabled = {
					type = "toggle",
					order = 10,
					name = L["Enable"],
				},
				target = {
					type = "select",
					order = 20,
					disabled = function() return not SPD.db.profile.general.sounds.enabled end,
					desc = L["Play a sound when your target has a dispellable aura."],
					name = L["target"],
					values = function() return List("sound") end,
				},
				focus = {
					type = "select",
					order = 30,
					disabled = function() return not SPD.db.profile.general.sounds.enabled or not SPD.db.profile.general.frames.focus.enabled end,
					desc = L["Play a sound when your focus has a dispellable aura."],
					name = L["focus"],
					values = function() return List("sound") end,
				},
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},
			},
		},
		priest = {
			type = "group",
			inline = true,
			order = 20,
			hidden = function() return not SPD.hasMassDisp end,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Priest and warrior specific"],
				},
				enhanceMassDisp = {
					type = "toggle",
					order = 10,
					name = L["Enhance immunity"],
					desc = L["Shows immunity spells in a different color."],
				},
				color = {
					type = "color",
					order = 20,
					name = L["Select color"],
					 get = function() return GetColor(SPD.db.profile.general.priest.color) end,
					 set = function(info, r, g ,b)
						SetColor(SPD.db.profile.general.priest.color, r, g, b)
					 end,
				},
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},
			},
		},
		misc = {
			type = "group",
			inline = true,
			order = 30,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Miscellaneous settings"],
				},
				message = {
					type = "toggle",
					order = 10,
					name = L["Welcome message"],
				},
				refresh = {
					type = "range",
					order = 20,
					name = L["Refresh speed"],
					desc = L["Don't touch it or you'll blow up the whole thing!"],
					min = 0.1, max = 1, step = 0.05,
				},
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},
			},
		},
	}
	
	return options
end

-- layout option pannel
function SPD:LayoutOptions()
	local UIScale = UIParent:GetScale()
	local UIWidth = UIParent:GetWidth()
	local UIHeight = UIParent:GetHeight()

	-- text options
	local function TextOptions()
		local textType = {"title", "barMain", "barTime", "barCount"}
		local args = {
			header = {
				type = "header",
				order = 0,
				name = L["Texts"],
			},
			font = {
				type = "select",
				order = 10,
				name = L["Text font"],
				values = function()	return List("font") end,
			},
			spaceSimpleSet = {
				type = "description",
				order = 19,
				name = " ",
				width = "full",
			},
			simpleSet = {
				type = "toggle",
				order = 20,
				name = L["Simple settings"],
				desc = L["Untick to finely tune text settings."],
			},
			space = {
				type = "description",
				order = 500,
				name = " ",
				width = "full",
			},
		}
		
		for i = 1, #textType do
			args[textType[i]] = {
				type = "group",
				order = 100 + i,
				hidden = function() return SPD.db.profile.layout.texts.simpleSet end,
				name = L[textType[i]],
				args = {
					size = {
						type = "range",
						order = 0,
						name = L["Size"],
						desc = L["Percentage of the frame height."],
						isPercent = true,
						min = 0, max = 1.5, step = 0.01, bigStep = 0.05,
					},
					shadow = {
						type = "toggle",
						order = 10,
						name = L["Text shadow"],
					},
					flag = {
						type = "select",
						order = 20,
						name = L["Text outline"],
						values = {
							[""] = L["None"],
							OUTLINE = L["Outline"],
							THICKOUTLINE = L["Thickoutline"],
						},
					},
					space1 = {
						type = "description",
						order = 30,
						name = " ",
						width = "full",
					},
					align = {
						type = "select",
						order = 40,
						name = L["Text alignment"],
						values = {
							CENTER = L["Center"],
							LEFT = L["Left"],
							RIGHT = L["Right"],
						},
					},
					ofx = {
						type = "range",
						order = 50,
						disabled = function() return SPD.db.profile.layout.texts[textType[i]].align == "CENTER" end,
						name = L["Horizontal offset"],
						min = 0, max = 10, step = 0.1, bigStep = 0.25,
					},
					ofy = {
						type = "range",
						order = 60,
						name = L["Vertical offset"],
						min = -10, max = 10, step = 0.1, bigStep = 0.25,
					},
					space2 = {
						type = "description",
						order = 70,
						name = " ",
						width = "full",
					},
					color = {
						type = "color",
						order = 80,
						name = L["Text color"],
						hasAlpha = true,
						get = function() return GetColor(SPD.db.profile.layout.texts[textType[i]].color) end,
						set = function(info, r, g, b, a)
							SetColor(SPD.db.profile.layout.texts[textType[i]].color, r, g, b, a)
							SPD:UpdateDisplayAndData("target", info)
							SPD:UpdateDisplayAndData("focus", info)
						end,
					},
				},
			}
		end
		
		return args
	end
	
	-- position options
	local function AnchorOptions(unit)
		local args = {}
		args = {
			xcd = {
				type = "range",
				order = 10,
				name = L["Horizontal position"],
				min = 0, max = round(UIWidth, 0), bigStep = 0.5,
				get = function() return SPD.db.profile.layout.anchor[unit].xcd / UIScale end,
				set = function(info, value)
					SPD.db.profile.layout.anchor[unit].xcd = value * UIScale
					SPD:UpdateDisplayAndData(unit, info)
				end,
			},
			ycd = {
				type = "range",
				order = 20,
				name = L["Vertical position"],
				min = 0, max = round(UIHeight, 0), bigStep = 0.1,
				get = function() return SPD.db.profile.layout.anchor[unit].ycd / UIScale end,
				set = function(info, value)
					SPD.db.profile.layout.anchor[unit].ycd = value * UIScale
					SPD:UpdateDisplayAndData(unit, info)
				end,
			},
			point = {
				type = "select",
				order = 30,
				name = L["Anchorage point"],
				values = {
					TOPLEFT = L["Top"],
					BOTTOMLEFT = L["Bottom"],
				},
			},
		}
		
		return args
	end
	
	-- background options
	local function BackgroundOptions(unit)
		local args = {}
		args = {
			color = {
				type = "color",
				order = 10,
				disabled = function() return not SPD.db.profile.layout.background.enabled end,
				name = L["Background color"],
				hasAlpha = true,
				get = function() return GetColor(SPD.db.profile.layout.background[unit].color) end,
				set = function(info, r, g, b, a)
					SetColor(SPD.db.profile.layout.background[unit].color, r, g, b, a)
					SPD:UpdateDisplayAndData("target", info)
					SPD:UpdateDisplayAndData("focus", info)
				end,
			},
			inset = {
				type = "range",
				order = 25,
				name = L["Inset"],
				min = -10, max = 10, step = 0.1, bigStep = 0.25,
			},
		}
		
		return args
	end
	
	-- border options
	local function BorderOptions(unit)
		local args = {}
		args = {
			color = {
				type = "color",
				order = 10,
				name = L["Border color"],
				hasAlpha = true,
				get = function() return GetColor(SPD.db.profile.layout.border[unit].color) end,
				set = function(info, r, g, b, a)
					SetColor(SPD.db.profile.layout.border[unit].color, r, g, b, a)
					SPD:UpdateDisplayAndData("target", info)
					SPD:UpdateDisplayAndData("focus", info)
				end,
			},
			size = {
				type = "range",
				order = 20,
				name = L["Border thickness"],
				min = 0.2, max = 35, step = 0.05,
				softMin = 0.5, softMax = 30, bigStep = 0.25,
			},
		}
		
		return args
	end

	-- title options
	function TitleOptions(unit)
		local args = {}
		args = {
			height = {
				type = "range",
				order = 10,
				name = L["Title height"],
				min = 3, max = 50, step = 0.05,
				softMin = 10, softMax = 25, bigStep = 0.25,
			},
			botpad = {
				type = "range",
				order = 20,
				name = L["Title padding"],
				min = -5, max = 10, step = 0.1,
				softMin = 0, softMax = 5, bigStep = 0.25,
			},
			opacity = {
				type = "range",
				order = 30,
				name = L["Title opacity"],
				min = 0, max = 1, step = 0.01, bigStep = 0.05,
			},
		}
		
		return args
	end
	
	-- bar options
	function BarOptions(unit)
		local args = {}
		args = {
			width = {
				type = "range",
				order = 20,
				name = L["Bar width"],
				min = 20, max = 300, step = 0.1,
				softMin = 50, softMax = 200, bigStep = 0.5,
			},
			height = {
				type = "range",
				order = 30,
				name = L["Bar height"],
				min = 3, max = 50, step = 0.05,
				softMin = 10, softMax = 25, bigStep = 0.25,
			},
			extraSize = {
				type = "range",
				order = 31,
				name = L["Extra size"],
				desc = L["Increases the size of the edge of the frame."],
				min = 0, max = 15, step = 0.1, bigStep = 0.25,
			},
			space2 = {
				type = "description",
				order = 35,
				name = " ",
				width = "full",
			},
			anchor = {
				type = "select",
				order = 40,
				name = L["Anchor"],
				desc = L["Bar anchorage"],
				values = function()
					local t = {
						LEFT = L["Left"],
						RIGHT = L["Right"],
					}
					return t
				end,
			},
			ypadding = {
				type = "range",
				order = 60,
				name = L["Vertical padding"],
				min = -5, max = 10, step = 0.1,
				softMin = 0, softMax = 5, bigStep = 0.25,
			},
			space3 = {
				type = "description",
				order = 65,
				name = " ",
				width = "full",
			},
			color = {
				type = "color",
				order = 70,
				name = L["Bar color"],
				hasAlpha = true,
				get = function() return GetColor(SPD.db.profile.layout.bar[unit].color) end,
				set = function(info, r, g, b, a)
					SetColor(SPD.db.profile.layout.bar[unit].color, r, g, b, a)
					SPD:UpdateDisplayAndData("target", info)
					SPD:UpdateDisplayAndData("focus", info)
				end,
			},
			bgShadow = {
				type = "range",
				order = 80,
				name = L["Background shade"],
				desc = L["Sets up the light/dark balance of the bar background."],
				min = 0, max = 1, step = 0.01, bigStep = 0.05,
			},
			bgOpacity = {
				type = "range",
				order = 90,
				name = L["Background opacity"],
				min = 0, max = 1, step = 0.01, bigStep = 0.05,
			},
		}
		
		return args
	end

	-- main options
	local options = {
		anchor = {
			type = "group",
			inline = true,
			order = 0,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Position"],
				},
				strata = {
					type = "select",
					order = 10,
					name = L["Strata"],
					values = {L["Low"], L["Medium"], L["High"]},
				},
				spaceTar = {
					type = "description",
					order = 15,
					name = " ",
					width = "full",
				},
				descTar = {
					type = "description",
					order = 20,
					fontSize = "medium",
					name = SPD.COLOR .. L["Target specific settings:"],
				},
				target = {
					type = "group",
					order = 25,
					inline = true,
					args = AnchorOptions("target"),
				},
				spaceFoc = {
					type = "description",
					order = 29,
					name = " ",
					width = "full",
				},
				descFoc = {
					type = "description",
					order = 30,
					fontSize = "medium",
					name = SPD.COLOR .. L["Focus specific settings:"],
				},
				focus = {
					type = "group",
					order = 35,
					disabled = function() return not SPD.db.profile.general.frames.focus.enabled end,
					inline = true,
					args = AnchorOptions("focus"),
				},				
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},
			},
		},
		background = {
			type = "group",
			inline = true,
			order = 10,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Background"],
				},
				enabled = {
					type = "toggle",
					order = 10,
					name = L["Enable background"],
				},
				texture = {
					type = "select",
					order = 20,
					disabled = function() return not SPD.db.profile.layout.background.enabled end,
					name = L["Background texture"],
					values = function()	return List("background") end,
				},
				spaceTar = {
					type = "description",
					order = 24,
					name = " ",
					width = "full",
				},
				descTar = {
					type = "description",
					order = 25,
					fontSize = "medium",
					name = SPD.COLOR .. L["Target specific settings:"],
				},
				target = {
					type = "group",
					order = 30,
					inline = true,
					disabled = function() return not SPD.db.profile.layout.background.enabled end,
					args = BackgroundOptions("target"),
				},
				spaceFoc = {
					type = "description",
					order = 34,
					name = " ",
					width = "full",
				},
				descFoc = {
					type = "description",
					order = 35,
					fontSize = "medium",
					name = SPD.COLOR .. L["Focus specific settings:"],
				},
				focusLikeTarget = {
					type = "toggle",
					order = 40,
					disabled = function() return not SPD.db.profile.layout.background.enabled or not SPD.db.profile.general.frames.focus.enabled end,
					name = L["Focus like target"],
					desc = L["Untick to access to focus settings."],
				},
				focus = {
					type = "group",
					order = 50,
					inline = true,
					hidden = function() return SPD.db.profile.layout.background.focusLikeTarget end,
					disabled = function() return not SPD.db.profile.layout.background.enabled or not SPD.db.profile.general.frames.focus.enabled end,
					args = BackgroundOptions("focus"),
				},				
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},
			},
		},
		border = {
			type = "group",
			inline = true,
			order = 20,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Border"],
				},
				enabled = {
					type = "toggle",
					order = 10,
					name = L["Enable border"],
				},
				texture = {
					type = "select",
					order = 20,
					disabled = function() return not SPD.db.profile.layout.border.enabled end,
					name = L["Border texture"],
					values = function() return List("border") end,
				},
				spaceTar = {
					type = "description",
					order = 24,
					name = " ",
					width = "full",
				},
				descTar = {
					type = "description",
					order = 25,
					fontSize = "medium",
					name = SPD.COLOR .. L["Target specific settings:"],
				},
				target = {
					type = "group",
					order = 30,
					inline = true,
					disabled = function() return not SPD.db.profile.layout.border.enabled end,
					args = BorderOptions("target"),
				},
				spaceFoc = {
					type = "description",
					order = 34,
					name = " ",
					width = "full",
				},
				descFoc = {
					type = "description",
					order = 35,
					fontSize = "medium",
					name = SPD.COLOR .. L["Focus specific settings:"],
				},
				focusLikeTarget = {
					type = "toggle",
					order = 40,
					disabled = function() return not SPD.db.profile.layout.border.enabled or not SPD.db.profile.general.frames.focus.enabled end,
					name = L["Focus like target"],
					desc = L["Untick to access to focus settings."],
				},
				focus = {
					type = "group",
					order = 50,
					inline = true,
					hidden = function() return SPD.db.profile.layout.border.focusLikeTarget end,
					disabled = function() return not SPD.db.profile.layout.border.enabled or not SPD.db.profile.general.frames.focus.enabled end,
					args = BorderOptions("focus"),
				},				
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},				
			},
		},
		title = {
			type = "group",
			inline = true,
			order = 30,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Title"],
				},
				prefix = {
					type = "toggle",
					order = 10,
					name = L["Title prefix"],
					desc = L["Displays unit type before unit name."],
				},
				prefixColor = {
					type = "color",
					order = 20,
					disabled = function() return not SPD.db.profile.layout.title.prefix end,
					name = L["Prefix color"],
					hasAlpha = true,
					get = function() return GetColor(SPD.db.profile.layout.title.prefixColor) end,
					set = function(info, r, g ,b, a)
						SetColor(SPD.db.profile.layout.title.prefixColor, r, g, b, a)
						SPD:SetFakeTitle("target")
						SPD:SetFakeTitle("focus")
					end,
				},
				spaceTar = {
					type = "description",
					order = 24,
					name = " ",
					width = "full",
				},
				descTar = {
					type = "description",
					order = 25,
					fontSize = "medium",
					name = SPD.COLOR .. L["Target specific settings:"],
				},
				target = {
					type = "group",
					order = 30,
					inline = true,
					args = TitleOptions("target"),
				},
				spaceFoc = {
					type = "description",
					order = 34,
					name = " ",
					width = "full",
				},
				descFoc = {
					type = "description",
					order = 35,
					fontSize = "medium",
					name = SPD.COLOR .. L["Focus specific settings:"],
				},
				focusLikeTarget = {
					type = "toggle",
					order = 40,
					disabled = function() return not SPD.db.profile.general.frames.focus.enabled end,
					name = L["Focus like target"],
					desc = L["Untick to access to focus settings."],
				},
				focus = {
					type = "group",
					order = 50,
					inline = true,
					hidden = function() return SPD.db.profile.layout.title.focusLikeTarget end,
					disabled = function() return not SPD.db.profile.general.frames.focus.enabled end,
					args = TitleOptions("focus"),
				},				
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},				
			},
		},
		bar = {
			type = "group",
			inline = true,
			order = 40,
			args = {
				header = {
					type = "header",
					order = 0,
					name = L["Bars"],
				},
				texture = {
					type = "select",
					order = 10,
					name = L["Texture"],
					values = function() return List("statusbar") end,
				},
				icon = {
					type = "group",
					inline = true,
					order = 20,
					args = {
						enabled = {
							type = "toggle",
							order = 1,
							name = L["Enable icon"],
						},
						padding = {
							type = "range",
							order = 3,
							disabled = function() return not SPD.db.profile.layout.bar.icon.enabled end,
							name = L["Icon padding"],
							min = 0, max = 5, step = 0.1, bigStep = 0.25,
						},
					},
				},
				displayType = {
					type = "select",
					order = 30,
					name = L["Bar display"],
					desc = L["Choose one of the three types of display for the timer bar."],
					values = function()
						local t = {L["Name, time"], L["Time, name"], L["Name only"]}
						return t
					end,
				},
				reverse = {
					type = "toggle",
					order = 31 ,
					name = L["Reverse"],
					desc = L["Reverses the direction of the bar."],
				},
				spaceTar = {
					type = "description",
					order = 34,
					name = " ",
					width = "full",
				},
				descTar = {
					type = "description",
					order = 35,
					fontSize = "medium",
					name = SPD.COLOR .. L["Target specific settings:"],
				},
				target = {
					type = "group",
					order = 40,
					inline = true,
					args = BarOptions("target"),
				},
				spaceFoc = {
					type = "description",
					order = 44,
					name = " ",
					width = "full",
				},
				descFoc = {
					type = "description",
					order = 45,
					fontSize = "medium",
					name = SPD.COLOR .. L["Focus specific settings:"],
				},
				focusLikeTarget = {
					type = "toggle",
					order = 50,
					disabled = function() return not SPD.db.profile.general.frames.focus.enabled end,
					name = L["Focus like target"],
					desc = L["Untick to access to focus settings."],
				},
				focus = {
					type = "group",
					order = 60,
					inline = true,
					hidden = function() return SPD.db.profile.layout.bar.focusLikeTarget end,
					disabled = function() return not SPD.db.profile.general.frames.focus.enabled end,
					args = BarOptions("focus"),
				},				
				space = {
					type = "description",
					order = 500,
					name = " ",
					width = "full",
				},				
			},	
		},
		texts = {
			type = "group",
			inline = true,
			order = 50,
			args = TextOptions(),
		},
	}

	return options
end

-- macro option pannel
function SPD:MacroOptions()
	local buttons = {
		["btn:1,"] = L["Left button"],
		["btn:2,"] = L["Right button"],
		["btn:3,"] = L["Middle button"],
		["btn:4,"] = L["Button 4"],
		["btn:5,"] = L["Button 5"],
	}
	local modifiers = {
		["mod:shift,"] = L["Shift"],
		["mod:alt,"] = L["Alt"],
		["mod:ctrl,"] = L["Ctrl"],
		[""] = L["No modifier"],
	}
	
	local options = {
		enabled = {
			type = "toggle",
			order = 1,
			name = L["Enable"]
		},
		name = {
			type = "input",
			order = 3,
			name = L["Macro name"],
			desc = L["Enter macro name."],
		},
		space1 = {
			type = "description",
			order = 5,
			name = " ",
			width = "full",
		},
		targetBtn = {
			type = "select",
			order = 7,
			disabled = function() return SPD.db.char.macro.advEdit end,
			name = L["Target mouse button"],
			desc = L["Selects the mouse button associated with target."],
			values = function() return buttons end,
		},	
		targetMod = {
			type = "select",
			order = 9,
			disabled = function() return SPD.db.char.macro.advEdit end,
			name = L["Target modifier key"],
			desc = L["Selects the modifier key associated with target."],
			values = function() return modifiers end,
		},
		space2 = {
			type = "description",
			order = 11,
			name = " ",
			width = "full",
		},
		focusBtn = {
			type = "select",
			order = 13,
			disabled = function() return SPD.db.char.macro.advEdit or not SPD.db.profile.general.frames.focus.enabled end,
			name = L["Focus mouse button"],
			desc = L["Selects the mouse button associated with focus."],
			values = function() return buttons end,
		},	
		focusMod = {
			type = "select",
			order = 15,
			disabled = function() return SPD.db.char.macro.advEdit or not SPD.db.profile.general.frames.focus.enabled end,
			name = L["Focus modifier key"],
			desc = L["Selects the modifier key associated with focus."],
			values = function() return modifiers end,
		},
		space3 = {
			type = "description",
			order = 17,
			name = " ",
			width = "full",
		},
		advEdit = {
			type = "toggle",
			order = 19,
			name = L["Advanced editing"],
		},
		editBox = {
			type = "input",
			order = 21,
			disabled = function() return not SPD.db.char.macro.advEdit end,
			name = L["Edit box"],
			width = "full",
			multiline = 5,
		},
	}

	return options
end

-- button option pannel
function SPD:BtnOptions()
	local UIWidth = UIParent:GetWidth()
	local UIHeight = UIParent:GetHeight()
	local UIScale = UIParent:GetScale()
	
	local function MakeOptPerUnit(unit)
		local textureList = {unit .. "_blue.tga", unit .. "_green.tga", unit .. "_green_light.tga",	unit .. "_orange.tga", unit .. "_violet.tga", unit .. "_red.tga"}
		for i, v in ipairs(textureList) do
			local string = string.gsub(v, ".tga", "")
			string = L[string.gsub(string, unit, "")]
			textureList[v] = string
			textureList[i] = nil
		end
			
		local t = {
			texture = {
				type = "select",
				order = 1,
				name = L["Button texture"],
				values = function() return textureList end,
			},
			space1 = {
				type = "description",
				order = 2,
				name = " ",
				width = "full",
			},
			anchor = {
				type = "group",
				order = 3,
				name = L["Anchor"],
				args = {
					xcd = {
						type = "range",
						order = 1,
						name = L["Horizontal position"],
						min = 0, max = round(UIWidth, 0), bigStep = 0.5,
						get = function() return SPD.db.profile.dispelBtn[unit].anchor.xcd / UIScale end,
						set = function(info, value)
							SPD.db.profile.dispelBtn[unit].anchor.xcd = value * UIScale
							SPD:SetDispelBtn(unit)
						end,
					},
					ycd = {
						type = "range",
						order = 3,
						name = L["Vertical position"],
						min = 0, max = round(UIHeight, 0), bigStep = 0.5,
						get = function() return SPD.db.profile.dispelBtn[unit].anchor.ycd / UIScale end,
						set = function(info, value)
							SPD.db.profile.dispelBtn[unit].anchor.ycd = value * UIScale
							SPD:SetDispelBtn(unit)
						end,
					},
				},
			},
			border = {
				type = "group",
				order = 5,
				disabled = function(info) return not SPD.db.profile.dispelBtn.borderEnabled or info[#info - 2] == "focus" and not SPD.db.profile.general.frames.focus.enabled end,
				name = L["Border"],
				args = {
					color = {
						type = "color",
						order = 1,
						name = L["Border color"],
						hasAlpha = true,
						get = function() return GetColor(SPD.db.profile.dispelBtn[unit].border.color) end,
						set = function(info, r, g, b, a)
							SetColor(SPD.db.profile.dispelBtn[unit].border.color, r, g, b, a)
							SPD:SetDispelBtn(unit)
						end,
					},
					size = {
						type = "range",
						order = 3,
						name = L["Border thickness"],
						min = 0.2, max = 35, step = 0.05,
						softMin = 0.5, softMax = 30, bigStep = 0.25,
					},
				},
			},
			background = {
				type = "group",
				order = 10,
				disabled = function(info) return not SPD.db.profile.dispelBtn.backgroundEnabled or info[#info - 2] == "focus" and not SPD.db.profile.general.frames.focus.enabled end,
				name = L["Background"],
				args = {
					color = {
						type = "color",
						order = 1,
						name = L["Background color"],
						hasAlpha = true,
						get = function() return GetColor(SPD.db.profile.dispelBtn[unit].background.color) end,
						set = function(info, r, g, b, a)
							SetColor(SPD.db.profile.dispelBtn[unit].background.color, r, g, b, a)
							SPD:SetDispelBtn(unit)
						end,
					},
					inset = {
						type = "range",
						order = 5,
						name = L["Inset"],
						min = -10, max = 10, step = 0.1, bigStep = 0.25,
					},
				},
			},
		}
		
		return t
	end
	
	local options = {
		userWarn = {
			type = "description",
			order = 1,
			fontSize = "medium",
			name = SPD.COLOR .. L["Please enable \"Config mode\" and target and/or focus a player or a npc in order to make the dispel button visible."],
		},
		space0 = {
			type = "description",
			order = 2,
			name = " ",
			width = "full",
		},
		enabled = {
			type = "toggle",
			order = 3,
			name = L["Enable"],
		},
		space1 = {
			type = "description",
			order = 4,
			name = " ",
			width = "full",
		},
		size = {
			type = "range",
			order = 5,
			name = L["Button size"],
			min = 15, max = 79, step = 0.1,
			softMin = 20, bigStep = 0.5,
		},
		extraSize = {
			type = "range",
			order = 6,
			name = L["Button edge size"],
			min = 0, max = 15, step = 0.1, bigStep = 0.5,
		},
		space11 = {
			type = "description",
			order = 7,
			name = " ",
			width = "full",
		},
		backgroundEnabled = {
			type = "toggle",
			order = 8,
			name = L["Enable background"],
		},
		borderEnabled = {
			type = "toggle",
			order = 9,
			name = L["Enable border"],
		},
		highlight = {
			type = "toggle",
			order = 10,
			name = L["MouseOver highlight"],
		},
		space2 = {
			type = "description",
			order = 11,
			name = " ",
			width = "full",
		},
		alphaActive = {
			type = "range",
			order = 12,
			name = L["Active button alpha"],
			desc = L["Sets button transparency when an aura can be dispelled."],
			min = 0, max = 1, step = 0.01, bigStep = 0.05,
		},
		alphaInactive = {
			type = "range",
			order = 13,
			name = L["Inactive button alpha"],
			desc = L["Sets button transparency when no aura can be dispelled."],
			min = 0, max = 1, step = 0.01, bigStep = 0.05,
		},
		space3 = {
			type = "description",
			order = 15,
			name = " ",
			width = "full",
		},
		header1 = {
			type = "header",
			order = 17,
			name = L["target"],
		},
		target = {
			type = "group",
			inline = true,
			order = 19,
			args = MakeOptPerUnit("target"),
		},
		space4 = {
			type = "description",
			order = 21,
			name = " ",
			width = "full",
		},
		header2 = {
			type = "header",
			order = 23,
			name = L["focus"],
		},
		focus = {
			type = "group",
			inline = true,
			disabled = function() return not SPD.db.profile.general.frames.focus.enabled end,
			order = 25,
			args = MakeOptPerUnit("focus"),
		},
	}

	return options
end

-- user customs lists
function SPD:CustomListOptions()
	local options = {}
	local optType = {"wl", "bl"}
	local input, isID
	
	local function ValidateInput(info, value)
		local isValide = false
		input = tostring(value)
		isID = false
		
		if input and string.find(input, "%d+") and not string.find(input, "%D") then
			input = tonumber(input)
			if GetSpellInfo(input) then
				isID = true
				isValide = true
			else
				print(SPD.COLOR .. L["This is not a valid spell ID."])
			end
		elseif input and not string.find(input, "[%d%c]") then
			isValide = true
		else
			print(SPD.COLOR .. L["This is not a valid input."])
		end
		
		return isValide
	end
	
	local function SpellMgmtOpt(customList)
		local args = {}
		local i = 1
		while SPD.db.profile[customList][i] do
			local spellName = SPD.db.profile[customList][i]
			
			args["spell" .. i] = {
				type = "group",
				inline = true,
				order = 1,
				args = {
					spellToggle = {
						type = "toggle",
						order = 1,
						name = SPD.COLOR .. spellName,
						desc = L["Toggle to enable/disable this aura."],
						width = "double",
						get = function()
							return SPD.db.profile[customList][spellName]
						end,
						set = function(info, value)
							SPD.db.profile[customList][spellName] = value
							SPD.target.auraHasChanged = true
							SPD.focus.auraHasChanged = true
						end,
					},
					spellRemove = {
						type = "execute",
						order = 3,
						name = L["Remove"],
						desc = L["Remove completly this aura from SP&D."],
						func = function()
							SPD.db.profile[customList][spellName] = nil
							for j, v in ipairs(SPD.db.profile[customList]) do
								if v == spellName then
									table.remove(SPD.db.profile[customList], j)
								end
							end
							
							wipe(SPD.options.args.customLists.args)
							SPD.options.args.customLists.args = SPD:CustomListOptions()
							print(SPD.COLOR .. format(L["%s has been removed from the %s."], spellName,  L[customList]))
							SPD.target.auraHasChanged = true
							SPD.focus.auraHasChanged = true
						end,
						confirm = true,
						confirmText = format(L["This will remove %s from your %s. Are you sure?"], spellName, L[customList]),
					},
				},
			}
			
			i = i + 1
		end
		
		return args
	end

	for i = 1, #optType do
		options[optType[i]] = {
			type = "group",
			inline = true,
			order = i,
			args = {
				header = {
					type = "header",
					order = 1,
					name = L[optType[i]],
				},
				descInput = {
					type = "description",
					order = 3,
					name = SPD.COLOR .. L[optType[i] .. "DescInput"],
					width = "full",
					fontSize = "medium",
				},
				input = {
					type = "input",
					order = 5,
					name = L["Add a spell"],
					desc = L["inputBox"],
					validate = ValidateInput,
					set = function(info, value)						
						local listLength = #SPD.db.profile[optType[i]]
						local name
						
						if not isID then
							name = input
						else
							name = GetSpellInfo(input)
						end
						
						if not SPD.db.profile[optType[i]][name] then
							SPD.db.profile[optType[i]][listLength + 1] = name
							SPD.db.profile[optType[i]][name] = true
							
							wipe(SPD.options.args.customLists.args)
							SPD.options.args.customLists.args = SPD:CustomListOptions()							
							
							print(SPD.COLOR .. format(L["%s has been added to the %s."], name, L[optType[i]]))
						else
							print(SPD.COLOR .. L["This aura is already registered."])
						end
						SPD.target.auraHasChanged = true
						SPD.focus.auraHasChanged = true
					end,
				},
				space = {
					type = "description",
					order = 7,
					name = " ",
					width = "full",
				},
				descSpellManagement = {
					type = "description",
					order = 9,
					name = SPD.COLOR .. L["Auras management:"],
					width = "full",
					fontSize = "medium",
					hidden = function()
						if #SPD.db.profile[optType[i]] == 0 then
							return true
						end
					end,
				},
				spellManagement = {
					type = "group",
					inline = true,
					order = 11,
					args = SpellMgmtOpt(optType[i])
				},
			},
		}
	end

	return options
end



-- Setting updates ------------------------

-- setting update function
function SPD:UpdateDisplayAndData(unit, info)
	SPD:SetSpecialCases(unit, info)
	SPD:UpdateConfigDisplay(unit, info)
	if SPD.F[unit] then
		SPD:SetMain(unit, SPD.F[unit])
		SPD:SetTitle(unit, SPD.F[unit], SPD.F[unit].title)
		SPD:SetBar(unit, SPD.F[unit])
		if SPD.F[unit].btn then
			SPD:SetDispelBtn(unit)
		end
	end
end

-- settings that modify other settings / that change SP&D constants
function SPD:SetSpecialCases(unit, info)
	if info[#info - 1] == "sounds" then
		SPD[unit].sound = LSM:Fetch("sound", SPD.db.profile.general.sounds[unit])
	elseif info[#info] == "maxAura" then
		local i = SPD.db.profile.general.frames[unit].maxAura + 1
		while SPD.F[unit].bar[i] do
			SPD.F[unit].bar[i].statusbar:Hide()
			i = i + 1
		end
	elseif info[#info] == "focusLikeTarget" and SPD.db.profile.layout[info[#info - 1]].focusLikeTarget then
		wipe(SPD.db.profile.layout[info[#info - 1]].focus)
		SPD.db.profile.layout[info[#info - 1]].focus = DeepCopy(SPD.db.profile.layout[info[#info - 1]].target)
	elseif info[#info - 1] == "target" and info[#info - 3] == "layout" and SPD.db.profile.layout[info[#info - 2]].focusLikeTarget then
		if type(SPD.db.profile.layout[info[#info - 2]].focus[info[#info]]) == "table" then
			SPD.db.profile.layout[info[#info - 2]].focus[info[#info]] = DeepCopy(SPD.db.profile.layout[info[#info - 2]].target[info[#info]])
		else
			SPD.db.profile.layout[info[#info - 2]].focus[info[#info]] = SPD.db.profile.layout[info[#info - 2]].target[info[#info]]
		end
	elseif info[#info] == "enabled" and info[#info - 1] == "focus" and info[#info - 3] == "general" then
		SPD:SetMacro()
	end
end



-- Config pannel managing ------------------

-- config options loading
function SPD:LoadConfig(optType)
	SPD.options = SPD.options or {
		type = "group",
		name = "Steal, Purge & Dispel",
		childGroups = "tab",
		disabled = IsAvailable,
		args = {},
	}
	
	if optType == "fake" then
		SPD.options.args = SPD:FakeOptions()
		ACR:RegisterOptionsTable("StealPurgeDispel", SPD.options)
		LibStub("AceConfigDialog-3.0"):AddToBlizOptions("StealPurgeDispel", "Steal, Purge & Dispel")
	else
		wipe(SPD.options.args)
		SPD.options.args = SPD:Options()
		SPD.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(SPD.db)
		SPD.configLoaded = true
	end
end

-- pannel switch when no dispel known anymore
function SPD:SwitchConfig(active)
	wipe(SPD.options.args)	
	if active and SPD.configLoaded then
		SPD.options.args = SPD:Options()
		SPD.options.args.profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(SPD.db)
	elseif active then
		SPD.options.args = SPD:FakeOptions()
	else
		SPD.options.args = SPD:NoDispelOptions()
	end
	ACR:NotifyChange("StealPurgeDispel")
end

-- profile changed managing
function SPD:ProfileChanged()
	local unitTable = {"target", "focus"}
	
	-- unit specific changes
	for j = 1, #unitTable do
		local unit = unitTable[j]
		if SPD.F[unit] then
			-- unused bar hiding
			local i = SPD.db.profile.general.frames[unit].maxAura + 1
			while SPD.F[unit].bar[i] do
				SPD.F[unit].bar[i].statusbar:Hide()
				i = i + 1
			end
			
			-- layout update
			SPD:SetMain(unit, SPD.F[unit])
			SPD:SetTitle(unit, SPD.F[unit], SPD.F[unit].title)
			SPD:SetBar(unit, SPD.F[unit])
			
			-- fake title text
			SPD:SetFakeTitle(unit)
		end
	end
	
	-- reload custom lists in config GUI
	wipe(SPD.options.args.customLists.args)
	SPD.options.args.customLists.args = SPD:CustomListOptions()
end

-- chat command handler
function SPD:OpenConfig()
	InterfaceOptionsFrame_OpenToCategory("Steal, Purge & Dispel")
	print(SPD.COLOR .. format("Steal, Purge & Dispel v%s %s", SPD.VERSION, "| Istaran - Medivh EU."))
	print(SPD.COLOR .. L["Welcome in SP&D options."])
end



-- Config mode display of the frames -------

-- config mode enable/disable by user
function SPD:ConfigMode(value)
	SPD.configMode = value

	-- create onupdate config frame
	if not SPD.F.config then
		SPD.F.config = CreateFrame("Frame", nil, UIParent)
		SPD.F.config:SetScript("OnUpdate", function(self, elapsed) SPD.ConfigUpdate(self, elapsed) end)
		SPD.F.config:Hide()
	end

	-- create fake aura tables, title text and enable/disable unit frame mouse interaction
	local unitTable = {"target", "focus"}
	if SPD.configMode then
		for _, unit in ipairs(unitTable) do
			SPD:SetFakeAuras(unit)
			SPD:SortingChanged(unit)
			SPD.F[unit]:EnableMouse(true)
			SPD.F[unit]:SetMovable(true)
			if SPD.F[unit].btn then
				SPD.F[unit].btn:SetMovable(true)
				SPD.F[unit].btn.handle:Show()
			end
			SPD:SetFakeTitle(unit)
		end
		SPD.F.config:Show()
	else
		for _, unit in ipairs(unitTable) do
			SPD.F[unit]:EnableMouse(false)
			SPD.F[unit]:SetMovable(false)
			SPD:StartScanning(unit)
			if SPD.F[unit].btn then
				SPD.F[unit].btn:SetMovable(false)
				SPD.F[unit].btn.handle:Hide()
			end
			SPD:SetMain(unit, SPD.F[unit])
		end
	end

	-- we will need dispel spell icon path later
	_, _, SPD.spellIcon = GetSpellInfo(SPD.spells[SPD.class])
end

-- config mode refresh
function SPD:ConfigUpdate(elapsed)
	self.TimeSinceLastUpdate = (self.TimeSinceLastUpdate or 0) + elapsed
	if self.TimeSinceLastUpdate > SPD.db.profile.general.misc.refresh then
			SPD:FakeScan("target")
			if SPD.db.profile.general.frames.focus.enabled then
				SPD:FakeScan("focus")
			end
		self.TimeSinceLastUpdate = 0
	end
end

-- config mode refresh: special calls
function SPD:UpdateConfigDisplay(unit, info)
	-- title text
	if info[#info] == "prefix" then
		SPD:SetFakeTitle(unit)
	-- sound
	elseif info[#info - 1] == "sounds" and info[#info] == unit then
		SPD[unit].hasPlayed = false
		SPD:SoundPlay(unit)
		SPD[unit].hasPlayed = false
	elseif info[#info] == "sorting" then
		SPD[unit].sortingHasChanged = true
	end
end

-- fake title
function SPD:SetFakeTitle(unit)
	local prefix = ""
	if SPD.db.profile.layout.title.prefix then
		prefix = ColorToHex(SPD.db.profile.layout.title.prefixColor) .. L[unit] .. L[": "] .. "|r"
	end
	SPD.F[unit].title.txt:SetText(prefix .. L[unit])
end

-- fake aura
function SPD:SetFakeAuras(unit)
	SPD.fakeAuras[unit] = SPD.fakeAuras[unit] or {}
	for i = 1, 10 do
		SPD.fakeAuras[unit][i] = SPD.fakeAuras[unit][i] or {}
		SPD.fakeAuras[unit][i].duration = math.random(1, 120)
		SPD.fakeAuras[unit][i].remain = SPD.fakeAuras[unit][i].duration
		SPD.fakeAuras[unit][i].count = math.floor(math.random(0, 20) / 10)
		SPD.fakeAuras[unit][i].name = L["Dispel me!!!"] .. i
		local immune = math.random(10)
		if immune > 8 then
			SPD.fakeAuras[unit][i].immune = true
		else
			SPD.fakeAuras[unit][i].immune = false
		end
		SPD.fakeAuras[unit][i].id = i
	end
end

-- aura sorting modified
function SPD:SortingChanged(unit)
	SPD[unit].sortingHasChanged = true
end

-- fake scan for config mode
function SPD:FakeScan(unit)
	-- sorting is triggered when user plays with type of sorting
	local sortingHasChanged = SPD[unit].sortingHasChanged

	-- timers
	for i = 1, #SPD.fakeAuras[unit] do
		SPD.fakeAuras[unit][i].remain = SPD.fakeAuras[unit][i].remain - SPD.db.profile.general.misc.refresh
	end

	-- sorting + bar color reseting
	if sortingHasChanged then
		if SPD.db.profile.general.bars.sorting == "ascending" then
			table.sort(SPD.fakeAuras[unit], function(a, b) return a.remain < b.remain end)
		elseif SPD.db.profile.general.bars.sorting == "descending" then
			table.sort(SPD.fakeAuras[unit], function(a, b) return a.remain > b.remain end)
		else
			table.sort(SPD.fakeAuras[unit], function(a, b) return a.id < b.id end)
		end
		SPD[unit].sortingHasChanged = false
		SPD:ResetBarColor(unit)
	end

	-- display
	for i = 1, SPD.db.profile.general.frames[unit].maxAura do
		if i <= #SPD.fakeAuras[unit] and SPD.fakeAuras[unit][i].remain > 0 then
			-- general display
			SPD.F[unit].bar[i].duration = SPD.fakeAuras[unit][i].duration
			SPD.F[unit].bar[i].value = SPD.fakeAuras[unit][i].remain
			if SPD.db.profile.layout.bar.reverse then
				SPD.F[unit].bar[i].value = SPD.fakeAuras[unit][i].duration - SPD.F[unit].bar[i].value
			end
			SPD.F[unit].bar[i].statusbar:SetMinMaxValues(0, SPD.fakeAuras[unit][i].duration)
			SPD.F[unit].bar[i].statusbar:SetValue(SPD.F[unit].bar[i].value)
			SPD.F[unit].bar[i].icon.tex:SetTexture(SPD.spellIcon)
			SPD.F[unit].bar[i].timeFrame.timeString:SetText(FormatTime(SPD.F[unit].bar[i].value))
			SPD.F[unit].bar[i].nameFrame.nameString:SetText(SPD.fakeAuras[unit][i].name)
			local count = SPD.fakeAuras[unit][i].count
			if count < 2 then
				count = ""
			end
			SPD.F[unit].bar[i].icon.countString:SetText(count)

			-- special cases
			if SPD.fakeAuras[unit][i].immune and SPD.db.profile.general.priest.enhanceMassDisp and SPD.hasMassDisp then
				SPD.F[unit].bar[i].statusbar:SetBackdropColor(GetColor(SPD.db.profile.general.priest.color))
				SPD.F[unit].bar[i].statusbar:SetStatusBarColor(GetColor(SPD.db.profile.general.priest.color))
				SPD.F[unit].bar[i].barColorHasChanged = true
			end
			
			SPD.F[unit].bar[i].statusbar:Show()
		end
	end
	
	local numAuras = #SPD.fakeAuras[unit]
	while numAuras > 0 do
		if SPD.fakeAuras[unit][numAuras].remain <= 0 then
			tremove(SPD.fakeAuras[unit], numAuras)
		end
		numAuras = numAuras - 1
	end
	local numBar = SPD.db.profile.general.frames[unit].maxAura
	while numBar > #SPD.fakeAuras[unit] do
		SPD.F[unit].bar[numBar].statusbar:Hide()
		numBar = numBar - 1
	end
	if numBar == 0 then
		SPD:SetFakeAuras(unit)
		SPD:SortingChanged(unit)
	end

	SPD.F[unit]:SetHeight(SPD.db.profile.layout.title[unit].height + SPD.db.profile.layout.title[unit].botpad + (numBar + 1) * SPD.db.profile.layout.bar[unit].ypadding + numBar * SPD.db.profile.layout.bar[unit].height + SPD.db.profile.layout.bar[unit].extraSize * 2)
	SPD.F[unit]:Show()
	if SPD.F[unit].btn then
		SPD.F[unit].btn:SetAlpha(SPD.db.profile.dispelBtn.alphaActive)
	end
	SPD:SoundPlay(unit)

	-- stops everything when exiting config mode or combat starts
	if not SPD.configMode or SPD.inCombat then
		-- unit frame
		SPD.F[unit]:Hide()

		-- button frames
		if SPD.F[unit].btn then
			SPD.F[unit].btn:SetAlpha(SPD.db.profile.dispelBtn.alphaInactive)
		end

		-- sound
		SPD[unit].hasPlayed = false

		-- mouse interaction
		SPD.F[unit]:EnableMouse(false)
		SPD.F[unit]:SetMovable(false)

		-- when triggered by combat
		if SPD.inCombat then
			SPD.configMode = false
			ACR:NotifyChange("StealPurgeDispel")
		end

		-- hides on update config frame
		SPD.F.config:Hide()

		-- cleans memory
		collectgarbage()
	end
end
