--[[
Title: Steal, Purge & Dispel - Terran Update
Author: Istaran | Updated By LogicallyUnfit - Terran Empire
Version: 1.1.1
Release date: 3/31/2020 8:00a
Steal, Purge & Dispel is licensed under GPLv3.
]]



-- ace addon creation and initialization ---

StealPurgeDispel = LibStub("AceAddon-3.0"):NewAddon("StealPurgeDispel", "AceConsole-3.0", "AceEvent-3.0")
local SPD = StealPurgeDispel

-- checks if addon must be enabled and registers player class
do
	local dispellers = {"MAGE", "PRIEST", "WARLOCK", "SHAMAN", "WARRIOR", "HUNTER", "ROGUE", "DEATHKNIGHT", "DRUID", "MONK"}
	local _, playerClass = UnitClass("player")
	for _, v in ipairs(dispellers) do
		if playerClass == v then
			SPD.class = playerClass
		end
	end
	if not SPD.class then
		return
	end
end

-- library initialization
local L = LibStub("AceLocale-3.0"):GetLocale("StealPurgeDispel", true)
local LSM = LibStub("LibSharedMedia-3.0")
local ACR = LibStub("AceConfigRegistry-3.0")

-- cache
local pairs, ipairs, type, tonumber, tostring, print, tinsert, tremove, wipe = pairs, ipairs, type, tonumber, tostring, print, tinsert, tremove, wipe
local strfind, strsub, floor, ceil, format = strfind, strsub, floor, ceil, format
local _

-- addon tables, contants and defaults
do
	SPD.F = {}					-- frame container
	SPD.aura = {}				-- info on each dispellable aura currently on units
	SPD.order = {}				-- display order of the auras
	SPD.skiped = {}
	SPD.target = {}				-- variable instanced for each type of unit
	SPD.focus = {}

	SPD.spells = {
		["MAGE"] = 30449,			-- spellsteal
		["PRIEST"] = 528,			-- dispel magic
		["SHAMAN"] = 370, 			-- purge
		["WARLOCK"] = 19505,		-- fellhunter's devour magic
		["WARRIOR"] = 23922,		-- shield slam
		["HUNTER"] = 19801,			-- tranq shot
		["ROGUE"] = 5938,			-- shiv
		["DEATHKNIGHT"] = 45477,	-- icy touch
		["DRUID"] = 2908,			-- soothe
		["MONK"] = 115450,			-- detox
		massDisp = 32375,			-- mass dispel
		shattT = 64382,				-- shattering throw
		immunityID1 = 45438,		-- ice block
		immunityID2 = 642,			-- divine shield
	}
	--[===[@debug@
	SPD.VERSION = "1.0.#"
	--@end-debug@]===]
	SPD.VERSION = SPD.VERSION or GetAddOnMetadata("StealPurgeDispel", "Version")
	SPD.COLOR = "|cff477BDC"

	SPD.defaults = {
		profile = {
			general = {
				frames = {
					hideShortAuras = true,
					hideShortTime = 2,
					target = {
						maxAura = 3,
					},
					focus = {
						enabled = true,
						maxAura = 3,
					},
				},
				bars = {
					sorting = "descending",
					decimal = "%.1f s",
				},
				sounds = {
					enabled = true,
					target = L["SP&D: "] .. "Kharazahn Bell",
					focus = L["SP&D: "] .. "Chimes",
				},
				priest = {
					enhanceMassDisp = true,
					color = {
						r = 1,
						g = 0,
						b = 0,
					}
				},			
				misc = {
					refresh = 0.1,
					message = false,
				},
			},
			layout = {
				anchor = {
					strata = 2,
					target = {
						xcd = UIParent:GetWidth() / 2 - 200,
						ycd = UIParent:GetHeight() / 2 + 200,
						point = "TOPLEFT",
					},
					focus = {
						xcd = UIParent:GetWidth() / 2 + 50,
						ycd = UIParent:GetHeight() / 2 + 200,
						point = "TOPLEFT",
					},
				},
				background = {
					enabled = true,
					texture = "Blizzard Tooltip",
					target = {
						color = {
							r = 0.2,
							g = 0,
							b = 0.65,
							a = 0.35,
						},
						inset = 0,
					},
					focusLikeTarget = true,
				},
				border = {
					enabled = true,
					texture = "Solid",
					target = {
						color = {
							r = 0.28,
							g = 0.48,
							b = 0.86,
							a = 1,
						},
						size = 1,
					},
					focusLikeTarget = true,
				},
				title = {
					prefix = false,
					prefixColor = {
						r = 0.82,
						g = 0.82,
						b = 0.82,
						a = 1,
					},
					target = {
						height = 15,
						opacity = 0.25,
						botpad = 2,
					},
					focusLikeTarget = true,
				},
				bar = {
					texture = "BantoBar",
					icon = {
						enabled = true,
						padding = 1,
					},
					displayType = 1, -- 1 => name, time; 2 => time, name; 3 => name only
					reverse = false,
					target = {
						width = 150,
						height = 17,
						extraSize = 5,
						anchor = "LEFT",
						ypadding = 1,
						color = {
							r = 0.28,
							g = 0.48,
							b = 0.86,
							a = 1,
						},
						bgShadow = 0.5,
						bgOpacity = 0.5,
					},
					focusLikeTarget = true,
				},
				texts = {
					font = "Friz Quadrata TT",
					simpleSet = true,
					title = {
						size = 0.7,
						flag = "",
						shadow = true,
						align = "LEFT",
						ofx = 0,
						ofy = 0,
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
					barMain = {
						size = 0.6,
						flag = "",
						shadow = true,
						align = "LEFT",
						ofx = 0,
						ofy = 0,
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
					barTime = {
						size = 0.5,
						flag = "",
						shadow = true,
						align = "RIGHT",
						ofx = 0,
						ofy = 0,
						color = {
							r = 1,
							g = 1,
							b = 1,
							a = 1,
						},
					},
					barCount = {
						size = 0.55,
						flag = "OUTLINE",
						shadow = false,
						align = "LEFT",
						ofx = 0,
						ofy = -4,
						color = {
							r = 1,
							g = 0.8,
							b = 0,
							a = 1,
						},
					},
				},
			},
			dispelBtn = {
				enabled = false,
				size = 32,
				extraSize = 4,
				highlight = true,
				alphaInactive = 0,
				alphaActive = 1,
				borderEnabled = true,
				backgroundEnabled = true,
				target = {
					anchor = {
						xcd = UIParent:GetWidth() / 2 - 58,
						ycd = UIParent:GetHeight() / 2 + 50,
					},
					texture = "target_blue.tga",
					border = {
						color = {
							r = 0.28,
							g = 0.48,
							b = 0.86,
							a = 1,
						},
						size = 1,
					},
					background = {
						color = {
							r = 0.2,
							g = 0,
							b = 0.65,
							a = 0.35,
						},
						inset = 0,				
					},
				},
			},
			wl = {},
			bl = {},
		},
		char = {
			macro = {
				enabled = true,
				name = "SP&D_macro",
				targetBtn = "btn:1,",
				focusBtn = "btn:2,",
				targetMod = "",
				focusMod = "",
				advEdit = false,
			},	
		},
	}
end



-- housekeeping functions ------------------

local function GetColor(t)
	return t.r, t.g, t.b, t.a
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

local function InvSide(side)
	if side == "RIGHT" then
		side = "LEFT"
	elseif side == "LEFT" then
		side = "RIGHT"
	end
	return side
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

local function GetTextSize(txtType, unit)
	local txtSize
	local sizeFactor = SPD.db.profile.layout.texts[txtType].size
	if txtType == "title" then
		txtSize = sizeFactor * SPD.db.profile.layout.title[unit].height
	else
		txtSize = sizeFactor * SPD.db.profile.layout.bar[unit].height
	end
	return txtSize
end



-- addon loading ---------------------------

-- addon OnEnable
function SPD:OnEnable()
	-- user data and chat command
	SPD.defaults.profile.layout.background.focus = DeepCopy(SPD.defaults.profile.layout.background.target)
	SPD.defaults.profile.layout.border.focus = DeepCopy(SPD.defaults.profile.layout.border.target)
	SPD.defaults.profile.layout.title.focus = DeepCopy(SPD.defaults.profile.layout.title.target)
	SPD.defaults.profile.layout.bar.focus = DeepCopy(SPD.defaults.profile.layout.bar.target)
	SPD.defaults.profile.dispelBtn.focus = DeepCopy(SPD.defaults.profile.dispelBtn.target)
	SPD.defaults.profile.dispelBtn.focus.anchor.xcd = SPD.defaults.profile.dispelBtn.focus.anchor.xcd + 108
	SPD.defaults.profile.dispelBtn.focus.texture = "focus_blue.tga"
	
	SPD.db = LibStub("AceDB-3.0"):New("SPD_data", SPD.defaults)
	SPD.db.RegisterCallback(self, "OnProfileChanged", "ProfileChanged")
	SPD.db.RegisterCallback(self, "OnProfileCopied", "ProfileChanged")
	SPD.db.RegisterCallback(self, "OnProfileReset", "ProfileChanged")
	
	SPD:RegisterChatCommand("stealpurgedispel","OpenConfig")
	SPD:RegisterChatCommand("sp&d", "OpenConfig")
	
	-- shared media registring
	local texturesPath = "Interface\\Addons\\StealPurgeDispel\\textures\\"

	LSM:Register("border", "Solid", "Interface\\Buttons\\WHITE8X8")
	
	LSM:Register("statusbar", "Aluminium", texturesPath .. "Aluminium.tga")	
	LSM:Register("statusbar", "Armory", texturesPath .. "Armory.tga")
	LSM:Register("statusbar", "BantoBar", texturesPath .. "BantoBar.tga")
	LSM:Register("statusbar", "Charcoal", texturesPath .. "Charcoal.tga")
	LSM:Register("statusbar", "Flat", texturesPath .. "Flat.tga")
	LSM:Register("statusbar", "Frost", texturesPath .. "Frost.tga")
	LSM:Register("statusbar", "Glaze", texturesPath .. "Glaze.tga")
	LSM:Register("statusbar", "Gloss", texturesPath .. "Gloss.tga")
	LSM:Register("statusbar", "Graphite", texturesPath .. "Graphite.tga")
	LSM:Register("statusbar", "HealBot", texturesPath .. "HealBot.tga")
	LSM:Register("statusbar", "LiteStep", texturesPath .. "LiteStep.tga")
	LSM:Register("statusbar", "Minimalist", texturesPath .. "Minimalist.tga")
	LSM:Register("statusbar", "Otravi", texturesPath .. "Otravi.tga")
	LSM:Register("statusbar", "Perl", texturesPath .. "Perl.tga")
	LSM:Register("statusbar", "Rocks", texturesPath .. "Rocks.tga")
	LSM:Register("statusbar", "Runes", texturesPath .. "Runes.tga")
	LSM:Register("statusbar", "Shard", texturesPath .. "Shard.tga")
	LSM:Register("statusbar", "Smooth", texturesPath .. "Smooth.tga")
	LSM:Register("statusbar", "Striped", texturesPath .. "Striped.tga")
	LSM:Register("statusbar", "Xeon", texturesPath .. "Xeon.tga")
	
	LSM:Register("sound", L["SP&D: "] .. "Achievment", [[Sound\Spells\AchievmentSound1.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "None Shall Pass", [[sound\CREATURE\BALEROC\VO_FL_BALEROC_KILL_05.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Alliance Bell", [[Sound\Doodad\BellTollAlliance.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Horde Bell", [[Sound\Doodad\BellTollHorde.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Kharazahn Bell", [[Sound\Doodad\KharazahnBellToll.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Night Elf Bell", [[Sound\Doodad\BellTollNightElf.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Chimes", [[Sound\Spells\ShaysBell.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Clock", [[Sound\INTERFACE\AlarmClockWarning3.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Fel Reaver", [[Sound\Creature\FelReaver\FelReaverPreAggro.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Ghoul 1", [[Sound\Creature\NorthrendGhoul\NorthrendGhoulAggro1.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Ghoul 2", [[Sound\Creature\NorthrendGhoul\NorthrendGhoulAggro2.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Ghoul 3", [[Sound\Creature\Ghoul\mGhoulWoundCritical1.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Not Prepared!", [[Sound\creature\Illidan\BLACK_Illidan_04.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Level Up!", [[Sound\INTERFACE\LevelUp.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Murloc", [[Sound\Creature\Murloc\mMurlocAggroOld.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Boss Warning", [[Sound\INTERFACE\RaidBossWarning.ogg]])
	LSM:Register("sound", L["SP&D: "] .. "Raid Warning", [[Sound\INTERFACE\RaidWarning.ogg]])

	-- event registring
	SPD:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", "PLAYER_SPECIALIZATION_CHANGED")
	SPD:RegisterEvent("PLAYER_LEVEL_UP", "PLAYER_LEVEL_UP")
	SPD:RegisterEvent("PLAYER_ENTERING_WORLD", "PLAYER_ENTERING_WORLD")
	SPD:RegisterEvent("UNIT_PET", "UNIT_PET")
	if SPD.class == "DEATHKNIGHT" then
		SPD:RegisterEvent("GLYPH_ADDED", "GLYPH_ADDED")
		SPD:RegisterEvent("GLYPH_REMOVED", "GLYPH_REMOVED")
	end
	
	-- end of loading is called if dispel spell is known. This is determined in the function "PLAYER_SPECIALIZATION_CHANGED".
end	
	
-- finishes loading process for relevant characters (i.e. knowing a dispel spell)
function SPD:CompleteLoading()
	-- event registring
	SPD:RegisterEvent("PLAYER_REGEN_DISABLED", "IsInCombat")
	SPD:RegisterEvent("PLAYER_REGEN_ENABLED", "IsInCombat")
	SPD:RegisterEvent("UI_SCALE_CHANGED", "ScaleChange")
	SPD:RegisterEvent("UNIT_AURA", "UNIT_AURA")
	SPD:RegisterEvent("PLAYER_TARGET_CHANGED", "PLAYER_TARGET_CHANGED")
	SPD:RegisterEvent("PLAYER_FOCUS_CHANGED", "PLAYER_FOCUS_CHANGED")
	
	-- target frame creation
	SPD.F.target = SPD:SetMain("target")
	SPD.F.target.title = SPD:SetTitle("target", SPD.F.target)
	SPD.F.target.bar = SPD:SetBar("target", SPD.F.target)
	SPD:FetchSound("target")

	-- focus frame creation
	SPD.F.focus = SPD:SetMain("focus")
	SPD.F.focus.title = SPD:SetTitle("focus", SPD.F.focus)
	SPD.F.focus.bar = SPD:SetBar("focus", SPD.F.focus)
	SPD:FetchSound("focus")

	-- update frame creation: drives on update script
	SPD.F.update = CreateFrame("Frame", nil, UIPARENT, BackdropTemplateMixin and "BackdropTemplate")
	SPD.F.update:SetScript("OnUpdate",  function(self, elapsed) SPD.OnUpdate(self, elapsed) end)
	SPD.F.update:Hide()
	
	-- macro creation
	if SPD.db.char.macro.enabled then
		SPD:SetMacro()
	end
	
	-- dispel button
	if SPD.db.profile.dispelBtn.enabled then
		SPD:SetDispelBtn("target")
		SPD:SetDispelBtn("focus")
	end
	
	-- Config pannel
	SPD:LoadConfig("fake")
	
	-- loading message
	if SPD.db.profile.general.misc.message then
		print(SPD.COLOR .. format(L["%s loaded."], "Steal, Purge & Dispel v" .. SPD.VERSION))
	end
	
	SPD.isLoaded = true
end

-- sound fetching
function SPD:FetchSound(unit)
	SPD[unit].sound = LSM:Fetch("sound", SPD.db.profile.general.sounds[unit])
end



-- Frame functions -------------------------

-- unit main frame creation and formating
function SPD:SetMain(unit, frame)
	frame = frame or CreateFrame("Frame", nil, UIParent, BackdropTemplateMixin and "BackdropTemplate")
	
	-- size
	if SPD.db.profile.layout.bar.icon.enabled then
		frame:SetWidth(SPD.db.profile.layout.bar[unit].width + SPD.db.profile.layout.bar[unit].height + SPD.db.profile.layout.bar.icon.padding + SPD.db.profile.layout.bar[unit].extraSize * 2)
	else
		frame:SetWidth(SPD.db.profile.layout.bar[unit].width + SPD.db.profile.layout.bar[unit].extraSize * 2)
	end
	frame:SetHeight(1)
	
	-- anchor
	local UIScale = UIParent:GetScale()
	local UIWidth = UIParent:GetWidth()
	local UIHeight = UIParent:GetHeight()
	frame:ClearAllPoints()
	frame:SetPoint(SPD.db.profile.layout.anchor[unit].point, UIParent, "CENTER", SPD.db.profile.layout.anchor[unit].xcd / UIScale - UIWidth / 2, SPD.db.profile.layout.anchor[unit].ycd / UIScale - UIHeight / 2)
	frame:SetClampedToScreen(true)
	
	-- strata
	local strata
	if SPD.db.profile.layout.anchor.strata == 1 then
		strata = "LOW"
	elseif SPD.db.profile.layout.anchor.strata == 2 then
		strata = "MEDIUM"
	else
		strata = "HIGH"
	end
	frame:SetFrameStrata(strata)
		
	-- backdrop
	local backdrop = {
		bgFile = LSM:Fetch("background", SPD.db.profile.layout.background.texture),
		edgeFile = LSM:Fetch("border", SPD.db.profile.layout.border.texture),
		tile = false,
		tileSize = 16,
		edgeSize = SPD.db.profile.layout.border[unit].size,
		insets = {
			left = SPD.db.profile.layout.background[unit].inset,
			right = SPD.db.profile.layout.background[unit].inset,
			top = SPD.db.profile.layout.background[unit].inset,
			bottom = SPD.db.profile.layout.background[unit].inset,
		},
	}
	if not SPD.db.profile.layout.background.enabled then
		backdrop.bgFile = " "
	end
	if not SPD.db.profile.layout.border.enabled then
		backdrop.edgeFile = " "
	end
	
	frame:SetBackdrop(backdrop)
	
	if SPD.db.profile.layout.background.enabled then
		frame:SetBackdropColor(GetColor(SPD.db.profile.layout.background[unit].color))
	end
	if SPD.db.profile.layout.border.enabled then
		frame:SetBackdropBorderColor(GetColor(SPD.db.profile.layout.border[unit].color))
	end
	
	-- moving scripts
	frame:SetScript("OnMouseDown", function(self, button)
		frame:StartMoving()
	end)
	frame:SetScript("OnMouseUp", function(self, button)
		frame:StopMovingOrSizing()
		local UIScale = UIParent:GetScale()
		SPD.db.profile.layout.anchor[unit].xcd = frame:GetLeft() * UIScale
		if SPD.db.profile.layout.anchor[unit].point == "TOPLEFT" then
			SPD.db.profile.layout.anchor[unit].ycd = frame:GetTop() * UIScale
		else
			SPD.db.profile.layout.anchor[unit].ycd = frame:GetBottom() * UIScale
		end
		ACR:NotifyChange("StealPurgeDispel")
	end)
	
	-- mouse interaction
	if not SPD.configMode then
		frame:EnableMouse(false)
		frame:SetMovable(false)
	end
	
	frame:Hide()
	return frame
end

-- title frame creation and formating
function SPD:SetTitle(unit, frame, title)
	title = title or CreateFrame("Frame", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
	
	if SPD.db.profile.layout.bar.icon.enabled then
		title:SetWidth(SPD.db.profile.layout.bar[unit].width + SPD.db.profile.layout.bar[unit].height + SPD.db.profile.layout.bar.icon.padding)
	else
		title:SetWidth(SPD.db.profile.layout.bar[unit].width)
	end
	title:SetHeight(SPD.db.profile.layout.title[unit].height)
	
	title:ClearAllPoints()
	title:SetPoint("TOP", frame, "TOP", 0, -SPD.db.profile.layout.bar[unit].ypadding - SPD.db.profile.layout.bar[unit].extraSize)
	
	title.tt = title.tt or title:CreateTexture()
	title.tt:SetAllPoints(title)
	title.tt:SetTexture(0, 0, 0, SPD.db.profile.layout.title[unit].opacity)
	
	title.txt = title.txt or title:CreateFontString()
	SPD:SetString(unit, title, "title", title.txt)

	title:Show()
	
	return title
end

-- timer bar factory
function SPD:SetBar(unit, frame)
	frame.bar = frame.bar or {}
	for i = 1, SPD.db.profile.general.frames[unit].maxAura do
		-- if frame is not created yet
		if frame.bar[i] == nil then
			frame.bar[i] = {}
			frame.bar[i].statusbar = CreateFrame("StatusBar", nil, frame, BackdropTemplateMixin and "BackdropTemplate")
			frame.bar[i].nameFrame = CreateFrame("Frame", nil, frame.bar[i].statusbar, BackdropTemplateMixin and "BackdropTemplate")
			frame.bar[i].timeFrame = CreateFrame("Frame", nil, frame.bar[i].statusbar, BackdropTemplateMixin and "BackdropTemplate")
			frame.bar[i].spark = CreateFrame("Frame", nil, frame.bar[i].statusbar, BackdropTemplateMixin and "BackdropTemplate")
			frame.bar[i].icon = CreateFrame("Frame", nil, frame.bar[i].statusbar, BackdropTemplateMixin and "BackdropTemplate")
			frame.bar[i].nameFrame.nameString = frame.bar[i].nameFrame:CreateFontString(nil, "OVERLAY")
			frame.bar[i].timeFrame.timeString = frame.bar[i].timeFrame:CreateFontString(nil, "OVERLAY")
			frame.bar[i].timeFrame.dummyString = frame.bar[i].timeFrame:CreateFontString(nil, "OVERLAY")
			frame.bar[i].icon.countString = frame.bar[i].icon:CreateFontString(nil, "OVERLAY")
			frame.bar[i].statusbar.texBack = frame.bar[i].statusbar:CreateTexture(nil, "BACKGROUND")
			frame.bar[i].statusbar.texMid = frame.bar[i].statusbar:CreateTexture(nil, "BORDER")
			frame.bar[i].spark.tex = frame.bar[i].spark:CreateTexture(nil, "OVERLAY")
			frame.bar[i].icon.tex = frame.bar[i].icon:CreateTexture(nil, "BACKGROUND")
		end
		
		local bar = frame.bar[i]
		
		-- frame texturing
		local r, g, b, a = GetColor(SPD.db.profile.layout.bar[unit].color)
		
		bar.statusbar.texBack:SetTexture(LSM:Fetch("statusbar", SPD.db.profile.layout.bar.texture))
		bar.statusbar.texBack:SetVertexColor(r, g, b, SPD.db.profile.layout.bar[unit].bgOpacity)
		bar.statusbar.texBack:SetAllPoints(bar.statusbar)
		
		bar.statusbar.texMid:SetTexture(0, 0, 0, SPD.db.profile.layout.bar[unit].bgShadow)
		bar.statusbar.texMid:SetAllPoints(bar.statusbar)
		
		bar.statusbar:SetStatusBarTexture(LSM:Fetch("statusbar", SPD.db.profile.layout.bar.texture), "ARTWORK")
		bar.statusbar:SetStatusBarColor(r, g, b, a)
		
		bar.spark.tex:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
		bar.spark.tex:SetBlendMode("ADD")
		bar.spark.tex:SetAllPoints(bar.spark)
		
		bar.icon.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		bar.icon.tex:SetAllPoints(bar.icon)
				
		-- frame sizing
		bar.statusbar:SetHeight(SPD.db.profile.layout.bar[unit].height)
		bar.width = SPD.db.profile.layout.bar[unit].width
		bar.statusbar:SetWidth(bar.width)
				
		bar.spark:SetHeight(SPD.db.profile.layout.bar[unit].height * 2.3)
		bar.spark:SetWidth(10)
		
		bar.icon:SetHeight(SPD.db.profile.layout.bar[unit].height)
		bar.icon:SetWidth(SPD.db.profile.layout.bar[unit].height)
		
		bar.nameFrame:SetHeight(SPD.db.profile.layout.bar[unit].height)
		
		bar.timeFrame:SetHeight(SPD.db.profile.layout.bar[unit].height)
				
		-- frame alignment and anchoring
		bar.statusbar:ClearAllPoints()
		bar.nameFrame:ClearAllPoints()
		bar.timeFrame:ClearAllPoints()
		bar.icon:ClearAllPoints()
		
		if SPD.db.profile.layout.bar.icon.enabled then
			if i > 1 then
				bar.icon:SetPoint("TOP" .. SPD.db.profile.layout.bar[unit].anchor, frame.bar[i - 1].icon, "BOTTOM" .. SPD.db.profile.layout.bar[unit].anchor, 0, -SPD.db.profile.layout.bar[unit].ypadding)
			else
				bar.icon:SetPoint("TOP" .. SPD.db.profile.layout.bar[unit].anchor, frame.title, "BOTTOM" .. SPD.db.profile.layout.bar[unit].anchor, 0, -SPD.db.profile.layout.title[unit].botpad)
			end
			local iconPadding = SPD.db.profile.layout.bar.icon.padding
			if SPD.db.profile.layout.bar[unit].anchor == "RIGHT" then
				iconPadding = -iconPadding
			end		
			bar.statusbar:SetPoint(SPD.db.profile.layout.bar[unit].anchor, bar.icon, InvSide(SPD.db.profile.layout.bar[unit].anchor), iconPadding, 0)
		else
			if i > 1 then
				bar.statusbar:SetPoint("TOP" .. SPD.db.profile.layout.bar[unit].anchor, frame.bar[i - 1].statusbar, "BOTTOM" .. SPD.db.profile.layout.bar[unit].anchor, 0, -SPD.db.profile.layout.bar[unit].ypadding)
			else
				bar.statusbar:SetPoint("TOP" .. SPD.db.profile.layout.bar[unit].anchor, frame.title, "BOTTOM" .. SPD.db.profile.layout.bar[unit].anchor, 0, -SPD.db.profile.layout.title[unit].botpad)
			end
		end
		bar.statusbar:SetReverseFill(SPD.db.profile.layout.bar[unit].anchor == "RIGHT")

		if SPD.db.profile.layout.bar.displayType == 1 then
			bar.nameFrame:SetPoint("LEFT", bar.statusbar, "LEFT")
			bar.nameFrame:SetPoint("RIGHT", bar.timeFrame, "LEFT")
			bar.timeFrame:SetPoint("RIGHT", bar.statusbar, "RIGHT")
		elseif SPD.db.profile.layout.bar.displayType == 2 then
			bar.timeFrame:SetPoint("LEFT", bar.statusbar, "LEFT")
			bar.nameFrame:SetPoint("LEFT", bar.timeFrame, "RIGHT")
			bar.nameFrame:SetPoint("RIGHT", bar.statusbar, "RIGHT")
		else
			bar.nameFrame:SetPoint("LEFT", bar.statusbar, "LEFT")
			bar.nameFrame:SetPoint("RIGHT", bar.statusbar, "RIGHT")
		end			
			
		-- onUpdate script
		bar.statusbar:SetScript("OnUpdate", function(self, elapsed)
			if bar.duration then
				if SPD.db.profile.layout.bar.reverse then
					bar.value = bar.value + elapsed
				else
					bar.value = bar.value - elapsed
				end
				
				-- spark
				local offset = bar.width * bar.value / bar.duration
				local anchorSide = SPD.db.profile.layout.bar[unit].anchor
				if SPD.db.profile.layout.bar[unit].anchor == "RIGHT" then
					offset = - offset
				end
				bar.spark:ClearAllPoints()
				if not SPD.db.profile.layout.bar.reverse and bar.value > 0 or SPD.db.profile.layout.bar.reverse and bar.value < bar.duration then
					bar.spark:SetPoint("CENTER", bar.statusbar, anchorSide, offset, 0)
					bar.spark:Show()
				else
					bar.spark:Hide()
				end
				
				-- status bar
				bar.statusbar:SetValue(bar.value)
			end
		end)
		
		-- string formating
		SPD:SetString(unit, bar.timeFrame, "barTime", bar.timeFrame.timeString)
		SPD:SetString(unit, bar.timeFrame, "dummy", bar.timeFrame.dummyString)
		bar.timeFrame.dummyString:SetText(format("%s m", "0.00"))
		bar.timeFrame:SetWidth(bar.timeFrame.dummyString:GetWidth())
		SPD:SetString(unit, bar.icon, "barCount", bar.icon.countString)
		SPD:SetString(unit, bar.nameFrame, "barMain", bar.nameFrame.nameString)

		-- showing/hiding
		bar.timeFrame.dummyString:Hide()
		if SPD.db.profile.layout.bar.icon.enabled then
			bar.icon:Show()
		else
			bar.icon:Hide()
		end
		if SPD.db.profile.layout.bar.displayType ~= 3 then
			bar.timeFrame.timeString:Show()
		else
			bar.timeFrame.timeString:Hide()
		end
		bar.statusbar:Hide()
		
		frame.bar[i] = bar
	end
	
	return frame.bar
end

-- strings creation and formating
function SPD:SetString(unit, frame, txtType, txt)
	local dummy
	if txtType == "dummy" then
		txtType = "barTime"
		dummy = true
	end
	
	txt:SetFont(LSM:Fetch("font", SPD.db.profile.layout.texts.font), GetTextSize(txtType, unit), SPD.db.profile.layout.texts[txtType].flag)
	if SPD.db.profile.layout.texts[txtType].shadow then
		txt:SetShadowColor(0, 0, 0, 1)
		txt:SetShadowOffset(1, -1)
	else
		txt:SetShadowColor(0, 0, 0, 0)
	end
	txt:SetTextColor(GetColor(SPD.db.profile.layout.texts[txtType].color))

	local ofx = SPD.db.profile.layout.texts[txtType].ofx
	if SPD.db.profile.layout.texts[txtType].align == "RIGHT" then
		ofx = -ofx
	end
	txt:ClearAllPoints()
	if SPD.db.profile.layout.texts[txtType].align ~= "CENTER" and not dummy then
		txt:SetPoint(SPD.db.profile.layout.texts[txtType].align, frame, SPD.db.profile.layout.texts[txtType].align, ofx, SPD.db.profile.layout.texts[txtType].ofy)
		txt:SetPoint(InvSide(SPD.db.profile.layout.texts[txtType].align), frame, InvSide(SPD.db.profile.layout.texts[txtType].align))
	else
		txt:SetAllPoints(frame)
	end
	txt:SetJustifyH(SPD.db.profile.layout.texts[txtType].align)
end



-- Dispel buttons -----------------------------------

function SPD:SetDispelBtn(unit)
	SPD.F[unit].btn = SPD.F[unit].btn or CreateFrame("Button", nil, UIParent, "SecureUnitButtonTemplate", BackdropTemplateMixin and "BackdropTemplate")
	
	-- sizing
	SPD.F[unit].btn:SetHeight(SPD.db.profile.dispelBtn.size + SPD.db.profile.dispelBtn.extraSize)
	SPD.F[unit].btn:SetWidth(SPD.db.profile.dispelBtn.size + SPD.db.profile.dispelBtn.extraSize)

	-- anchoring
	local UIScale = UIParent:GetScale()
	local UIWidth = UIParent:GetWidth()
	local UIHeight = UIParent:GetHeight()
	SPD.F[unit].btn:ClearAllPoints()
	SPD.F[unit].btn:SetPoint("TOPLEFT", UIParent, "CENTER", SPD.db.profile.dispelBtn[unit].anchor.xcd / UIScale - UIWidth / 2, SPD.db.profile.dispelBtn[unit].anchor.ycd / UIScale - UIHeight / 2)
	SPD.F[unit].btn:SetClampedToScreen(true)

	-- texture
	local backdrop = {
		bgFile = LSM:Fetch("background", SPD.db.profile.layout.background.texture),
		edgeFile = LSM:Fetch("border", SPD.db.profile.layout.border.texture),
		tile = false,
		tileSize = 16,
		edgeSize = SPD.db.profile.dispelBtn[unit].border.size,
		insets = {
			left = SPD.db.profile.dispelBtn[unit].background.inset,
			right = SPD.db.profile.dispelBtn[unit].background.inset,
			top = SPD.db.profile.dispelBtn[unit].background.inset,
			bottom = SPD.db.profile.dispelBtn[unit].background.inset,
		},
	}
	if not SPD.db.profile.dispelBtn.borderEnabled then
		backdrop.edgeFile = ""
	end
	if not SPD.db.profile.dispelBtn.backgroundEnabled then
		backdrop.bgFile = ""
	end
	SPD.F[unit].btn:SetBackdrop(backdrop)
	SPD.F[unit].btn:SetBackdropColor(GetColor(SPD.db.profile.dispelBtn[unit].background.color))
	SPD.F[unit].btn:SetBackdropBorderColor(GetColor(SPD.db.profile.dispelBtn[unit].border.color))
	SPD.F[unit].btn:SetAlpha(SPD.db.profile.dispelBtn.alphaInactive)
	
	-- button texture
	SPD.F[unit].btn.texture = SPD.F[unit].btn.texture or SPD.F[unit].btn:CreateTexture(nil, "ARTWORK")
	SPD.F[unit].btn.texture:ClearAllPoints()
	SPD.F[unit].btn.texture:SetPoint("TOPLEFT", SPD.F[unit].btn, "TOPLEFT", SPD.db.profile.dispelBtn.extraSize, -SPD.db.profile.dispelBtn.extraSize)
	SPD.F[unit].btn.texture:SetPoint("BOTTOMRIGHT", SPD.F[unit].btn, "BOTTOMRIGHT", -SPD.db.profile.dispelBtn.extraSize, SPD.db.profile.dispelBtn.extraSize)
	SPD.F[unit].btn.texture:SetTexture("Interface\\Addons\\StealPurgeDispel\\buttons\\" .. SPD.db.profile.dispelBtn[unit].texture)

	-- highlight on mouseover
	SPD.F[unit].btn.highL = SPD.F[unit].btn.highL or SPD.F[unit].btn:CreateTexture(nil, "HIGHLIGHT")
	SPD.F[unit].btn.highL:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
	SPD.F[unit].btn.highL:ClearAllPoints()
	SPD.F[unit].btn.highL:SetAllPoints(SPD.F[unit].btn)
	SPD.F[unit].btn.highL:SetBlendMode("ADD")
	if SPD.db.profile.dispelBtn.highlight then
		SPD.F[unit].btn.highL:SetAlpha(0.5)
	else
		SPD.F[unit].btn.highL:SetAlpha(0)
	end
	
	-- sound on click
	SPD.F[unit].btn:SetScript("PreClick", function(self)
		PlaySound("GLUECHARCUSTOMIZATIONMOUSEUP", "SFX")
	end)
	
	-- button moving
	SPD.F[unit].btn.handle = SPD.F[unit].btn.handle or CreateFrame("Frame", nil, SPD.F[unit].btn, BackdropTemplateMixin and "BackdropTemplate")
	SPD.F[unit].btn.handle:SetHeight(1)
	SPD.F[unit].btn.handle:SetWidth(1)
	SPD.F[unit].btn.handle:ClearAllPoints()
	SPD.F[unit].btn.handle:SetAllPoints(SPD.F[unit].btn)
	SPD.F[unit].btn.handle:SetMovable(false)
	SPD.F[unit].btn.handle:EnableMouse(true)
	if not SPD.configMode then
		SPD.F[unit].btn.handle:Hide()
	end

	SPD.F[unit].btn.handle:SetScript("OnMouseDown", function(self, button)
	SPD.F[unit].btn:StartMoving()
	end)
	SPD.F[unit].btn.handle:SetScript("OnMouseUp", function(self, button)
		SPD.F[unit].btn:StopMovingOrSizing()
		local UIScale = UIParent:GetScale()
		SPD.db.profile.dispelBtn[unit].anchor.xcd = SPD.F[unit].btn:GetLeft() * UIScale
		SPD.db.profile.dispelBtn[unit].anchor.ycd = SPD.F[unit].btn:GetTop() * UIScale
		ACR:NotifyChange("StealPurgeDispel")
	end)
	
	-- secure template attributes
	if SPD.db.profile.dispelBtn.enabled and (unit == "target" or unit == "focus" and SPD.db.profile.general.frames.focus.enabled) then
		SPD.F[unit].btn:SetAttribute("unit", unit)
		RegisterUnitWatch(SPD.F[unit].btn, false)
		SPD.F[unit].btn:SetAttribute("type", "spell")
		local spell = GetSpellInfo(SPD.spells[SPD.class])
		SPD.F[unit].btn:SetAttribute("spell", spell)
	else
		SPD.F[unit].btn:SetAttribute("unit", nil)
		SPD.F[unit].btn:Hide()
	end
end



-- Macro -----------------------------------

function SPD:SetMacro(name)
	local spell = GetSpellInfo(SPD.spells[SPD.class])
	local name = name or SPD.db.char.macro.name
	
	-- if custom editing is disabled
	if not SPD.db.char.macro.advEdit then
		if SPD.db.profile.general.frames.focus.enabled then
			SPD.db.char.macro.editBox = "#showtooltip " .. spell .." \n/stopcasting\n/cast [" .. SPD.db.char.macro.targetBtn .. SPD.db.char.macro.targetMod .. "@target] " .. spell .. "; [" .. SPD.db.char.macro.focusBtn .. SPD.db.char.macro.focusMod .. "@focus] " .. spell
		else
			SPD.db.char.macro.editBox = "#showtooltip " .. spell .." \n/stopcasting\n/cast [" .. SPD.db.char.macro.targetBtn .. SPD.db.char.macro.targetMod .. "@target] " .. spell
		end
	end
	
	if GetMacroInfo(name) and SPD.db.char.macro.enabled then
		EditMacro(name, SPD.db.char.macro.name, nil, SPD.db.char.macro.editBox)
	elseif SPD.db.char.macro.enabled then
		local _, perChar = GetNumMacros()
		if perChar < 18 then	-- 18 is the max number of macros per character
			CreateMacro(SPD.db.char.macro.name, "INV_Misc_QuestionMark", SPD.db.char.macro.editBox, 1)
		else
			print(SPD.COLOR .. L["errorMacro"])
			UIErrorsFrame:AddMessage(SPD.COLOR .. L["errorMacro"])
		end
	else
		DeleteMacro(SPD.db.char.macro.name)
	end
end



-- Event functions -------------------------

-- combat checking
function SPD:IsInCombat(event)
	SPD.inCombat = true and event == "PLAYER_REGEN_DISABLED"
	SPD.configMode = false and event == "PLAYER_REGEN_DISABLED"
	ACR:NotifyChange("StealPurgeDispel")
end

-- scale changing
function SPD:ScaleChange()
	local UIScale = UIParent:GetScale()

	-- target
	SPD.db.profile.layout.anchor.target.xcd = SPD.F.target:GetLeft() * UIScale
	if SPD.db.profile.layout.anchor.target.point == "TOPLEFT" then
		SPD.db.profile.layout.anchor.target.ycd = SPD.F.target:GetTop() * UIScale
	else
		SPD.db.profile.layout.anchor.target.ycd = SPD.F.target:GetBottom() * UIScale
	end
	
	-- focus
	SPD.db.profile.layout.anchor.focus.xcd = SPD.F.focus:GetLeft() * UIScale
	if SPD.db.profile.layout.anchor.focus.point == "TOPLEFT" then
		SPD.db.profile.layout.anchor.focus.ycd = SPD.F.focus:GetTop() * UIScale
	else
		SPD.db.profile.layout.anchor.focus.ycd = SPD.F.focus:GetBottom() * UIScale
	end
end

-- aura applied/removed checking
function SPD:UNIT_AURA(event, unit)
	if unit == "target" or unit == "focus" then
		SPD[unit].auraHasChanged = true
	end
end

-- this function controls addon update and is triggerd by the 2 events following
function SPD:StartScanning(unit)
	if not SPD.configMode and (UnitExists("target") or UnitExists("focus") and SPD.db.profile.general.frames.focus.enabled) then
		local unitName = UnitName(unit) or ""
		local prefix = ""
		if SPD.db.profile.layout.title.prefix then
			prefix = ColorToHex(SPD.db.profile.layout.title.prefixColor) .. L[unit] .. L[": "] .. "|r"
		end
		SPD.F[unit].title.txt:SetText(prefix .. unitName)
		SPD.F.update:Show()
	end
end

function SPD:PLAYER_TARGET_CHANGED()
	SPD.target.auraHasChanged = true
	SPD:StartScanning("target")
end

function SPD:PLAYER_FOCUS_CHANGED()
	SPD.focus.auraHasChanged = true
	SPD:StartScanning("focus")
end

-- this function checks that the dispel spell is known and is triggered by the 2 events following
function SPD:SpellCheck()
	if SPD.class == "DEATHKNIGHT" then
		local glyphIT = false
		for i = 1, NUM_GLYPH_SLOTS do
			local enabled, glyphType, _, glyphID = GetGlyphSocketInfo(i)
			if enabled and glyphType == 1 then	-- 1 is for major glyph
				if glyphID and glyphID == 58631	then	-- IT glyph id
					glyphIT = true
				end
			end
		end
		SPD.spellIsKnown = glyphIT
	else
		local isPet = true and SPD.class == "WARLOCK"
		SPD.spellIsKnown = IsSpellKnown(SPD.spells[SPD.class], isPet)
		if SPD.class == "PRIEST" and IsSpellKnown(SPD.spells.massDisp) or SPD.class == "WARRIOR" and IsSpellKnown(SPD.spells.shattT) then
			SPD.hasMassDisp = true
		end
	end

	-- calls end of loading process if necessary and controls addon elements when addon must not be functionnal (spec change); only executed if out of combat
	if not SPD.inCombat then
		local unitTable = {"target", "focus"}
		if SPD.spellIsKnown and not SPD.isLoaded then
			SPD:CompleteLoading()
			SPD:PLAYER_TARGET_CHANGED()
			SPD:PLAYER_FOCUS_CHANGED()			
		elseif not SPD.spellIsKnown and SPD.isLoaded then
			for _, unit in ipairs(unitTable) do
				if SPD.F[unit].btn then
					SPD.F[unit].btn:SetAttribute("unit", nil)
					SPD.F[unit].btn:Hide()
				end
				if SPD.F[unit] then
					SPD.F[unit]:Hide()
				end
			end
			SPD.F.update:Hide()
			SPD:SwitchConfig(false)
			SPD.hasBeenDisabled = true
		elseif SPD.hasBeenDisabled then
			for _, unit in ipairs(unitTable) do
				if SPD.F[unit].btn then
					SPD:SetDispelBtn(unit)
				end
			end
			SPD:PLAYER_TARGET_CHANGED()
			SPD:PLAYER_FOCUS_CHANGED()
			SPD:SwitchConfig(true)
			SPD.hasBeenDisabled = false
		end
	end
end

function SPD:PLAYER_SPECIALIZATION_CHANGED()
	SPD:SpellCheck()
end

function SPD:PLAYER_LEVEL_UP()
	SPD:SpellCheck()
end

function SPD:PLAYER_ENTERING_WORLD()
	SPD:SpellCheck()
end

function SPD:GLYPH_ADDED()
	SPD:SpellCheck()
end

function SPD:GLYPH_REMOVED()
	SPD:SpellCheck()
end

function SPD:UNIT_PET(event, unit)
	if unit == "player" then
		SPD:SpellCheck()
	end
end



-- on update functions ---------------------

-- unit scanning for auras to be removed
function SPD:Scan(unit)
	-- prevents execution of the rest of the function if the unit cannot be dispelled anyway
	if not UnitCanAttack("player", unit) then
		SPD.F[unit]:Hide()
		if SPD.F[unit].btn then
			SPD.F[unit].btn:SetAlpha(SPD.db.profile.dispelBtn.alphaInactive)
		end
		SPD[unit].hasPlayed = false
		return
	end
	
	-- LUA sort function seems to generate memory garbage. To avoid calling it each cycle, SPD.order table undergoes sorting and stores in which order auras
	-- must be shown by putting the aura spell id in value. From cycle n to n + 1, this table isn't modified if no UNIT_AURA event is triggered and thus
	-- no sorting is made. SPD.order is then used to display in the correct order auras stored in SPD.aura and identified by their spell ids as keys. If an
	-- aura is added or removed (UNIT_AURA event via booleen auraHasChanged), SPD.order is rebuilt and sorted.
	
	-- table and local vars initialization
	SPD.aura[unit] = SPD.aura[unit] or {}
	SPD.order[unit] = SPD.order[unit] or {}
	SPD.skiped[unit] = SPD.skiped[unit] or {}
	
	local auraHasChanged = SPD[unit].auraHasChanged
	local current = GetTime()
	local remain = 0
	local numBar = 0
	local j = 1	-- increment for ordering each detected aura
	
	-- allows to rebuild the aura skipped table for removing undesired auras in SPD.order related to remaining duration
	if auraHasChanged then
		wipe(SPD.skiped[unit])
	end
	
	-- unit scanning for auras
	local i = 1
	while true do
		local nextLoop
		-- 1.1.0 - Updated UnitAura for New API Output.
		-- local name, _, icon, count, _, duration, expTime, _, isDispellable, _, spellID = UnitAura(unit, i, "HELPFUL")
		local name, icon, count, _, duration, expTime, _, isDispellable, _, spellID = UnitAura(unit, i, "HELPFUL")
		if name then
			remain = expTime - current
			if isDispellable then
				-- IceBlock and Divine Shield can only be dispelled with mass dispel
				if (spellID == SPD.spells.immunityID1 or spellID == SPD.spells.immunityID2) and not SPD.hasMassDisp then
					nextLoop = true
				end
				-- blacklist check
				if SPD.db.profile.bl then
					for k = 1, #SPD.db.profile.bl do
						if SPD.db.profile.bl[k] == name and SPD.db.profile.bl[name] then
							nextLoop = true
						end
					end
				end
				-- if none of the above
				if not nextLoop then
					SPD:RegisterAuras(unit, spellID, name, icon, remain, duration, count)
					if auraHasChanged then
						SPD.order[unit][j] = spellID
						j = j + 1
					end
				end
			end
			-- custom white list scanning
			for k = 1, #SPD.db.profile.wl do
				if SPD.db.profile.wl[k] == name and SPD.db.profile.wl[name] then
					SPD:RegisterAuras(unit, spellID, name, icon, remain, duration, count)
					if auraHasChanged then
						SPD.order[unit][j] = spellID
						j = j + 1
					end
				end
			end
			-- removes any aura from the SPD.order table if remaining duration < to what user set in hideShortTime var or < to refresh time
			if SPD.db.profile.general.frames.hideShortAuras and remain < SPD.db.profile.general.frames.hideShortTime and duration ~= 0 or remain < SPD.db.profile.general.misc.refresh and duration ~= 0 then
				if not SPD.skiped[unit][spellID] then
					for index in ipairs(SPD.order[unit]) do
						if SPD.order[unit][index] == spellID then
							tremove(SPD.order[unit], index)
							j = j - 1
							SPD.skiped[unit][spellID] = true
						end
					end
				end
			elseif SPD.skiped[unit][spellID] then
				SPD.skiped[unit][spellID] = false
			end
		else
			-- purges SPD.order from old ids unused in this cycle at the end of the complete scanning if order must be altered
			if auraHasChanged then
				for k = j, #SPD.order[unit] do
					SPD.order[unit][k] = nil
				end
			end
			break
		end
		i = i + 1
	end
	
	-- table sorting and bar coloring reset
	if auraHasChanged then
		SPD:SortAuraTable(unit)
		SPD:ResetBarColor(unit)
	end
	
	-- display
	if SPD.order[unit] then
		numBar = #SPD.order[unit]
	end
	if numBar > SPD.db.profile.general.frames[unit].maxAura then
		numBar = SPD.db.profile.general.frames[unit].maxAura
	end
		
	if numBar > 0 then
		for k = 1, numBar do
			-- general display
			SPD.F[unit].bar[k].duration = SPD.aura[unit][SPD.order[unit][k]].duration
			SPD.F[unit].bar[k].value = SPD.aura[unit][SPD.order[unit][k]].remain
			if SPD.db.profile.layout.bar.reverse then
				SPD.F[unit].bar[k].value = SPD.F[unit].bar[k].duration - SPD.F[unit].bar[k].value
			end
			SPD.F[unit].bar[k].statusbar:SetMinMaxValues(0, SPD.aura[unit][SPD.order[unit][k]].duration)
			SPD.F[unit].bar[k].statusbar:SetValue(SPD.F[unit].bar[k].value)
			SPD.F[unit].bar[k].icon.tex:SetTexture(SPD.aura[unit][SPD.order[unit][k]].icon)
			SPD.F[unit].bar[k].timeFrame.timeString:SetText(FormatTime(SPD.F[unit].bar[k].value))
			SPD.F[unit].bar[k].nameFrame.nameString:SetText(SPD.aura[unit][SPD.order[unit][k]].name)
			SPD.F[unit].bar[k].icon.countString:SetText(SPD.aura[unit][SPD.order[unit][k]].count)
			
			-- special cases
			if (SPD.order[unit][k] == SPD.spells.immunityID1 or SPD.order[unit][k] == SPD.spells.immunityID2) and SPD.db.profile.general.priest.enhanceMassDisp and SPD.hasMassDisp then	-- we don't want that someone else than a priest or a warrior adding IB and DS in his white list can see enhance mass dispel warnings
				SPD.F[unit].bar[k].statusbar:SetBackdropColor(GetColor(SPD.db.profile.general.priest.color))
				SPD.F[unit].bar[k].statusbar:SetStatusBarColor(GetColor(SPD.db.profile.general.priest.color))
				SPD.F[unit].bar[k].barColorHasChanged = true
			end
			if SPD.aura[unit][SPD.order[unit][k]].duration == 0 then
				SPD.F[unit].bar[k].duration = nil
				SPD.F[unit].bar[k].value = 1
				SPD.F[unit].bar[k].statusbar:SetMinMaxValues(0, 1)
				SPD.F[unit].bar[k].statusbar:SetValue(1)
				SPD.F[unit].bar[k].timeFrame.timeString:SetText("\226\136\158")
				SPD.F[unit].bar[k].spark:Hide()
			end
			
			SPD.F[unit].bar[k].statusbar:Show()
		end
		SPD.F[unit]:SetHeight(SPD.db.profile.layout.title[unit].height + SPD.db.profile.layout.title[unit].botpad + (numBar + 1) * SPD.db.profile.layout.bar[unit].ypadding + numBar * SPD.db.profile.layout.bar[unit].height + SPD.db.profile.layout.bar[unit].extraSize * 2)
		SPD.F[unit]:Show()
		if SPD.F[unit].btn then
			SPD.F[unit].btn:SetAlpha(SPD.db.profile.dispelBtn.alphaActive)
		end
		SPD:SoundPlay(unit)
	else
		SPD.F[unit]:Hide()
		if SPD.F[unit].btn then
			SPD.F[unit].btn:SetAlpha(SPD.db.profile.dispelBtn.alphaInactive)
		end
		SPD[unit].hasPlayed = false
	end
	
	-- hides unused bars
	local l = numBar
	while l < SPD.db.profile.general.frames[unit].maxAura do
		l = l + 1
		SPD.F[unit].bar[l].statusbar:Hide()
	end
	
	-- cleans aura table
	SPD:ClearAuraTable(unit)
end

-- aura registering
function SPD:RegisterAuras(unit, spellID, name, icon, remain, duration, count)
	SPD.aura[unit][spellID] = SPD.aura[unit][spellID] or {}
	SPD.aura[unit][spellID].name = name
	SPD.aura[unit][spellID].icon = icon
	SPD.aura[unit][spellID].remain = remain
	SPD.aura[unit][spellID].duration = duration
	if count < 2 then
		count = ""
	end
	SPD.aura[unit][spellID].count = count
end

-- SPD.order sorting
function SPD:SortAuraTable(unit)
	if SPD.db.profile.general.bars.sorting == "ascending" then
		table.sort(SPD.order[unit], function(a, b) return SPD.aura[unit][a].remain < SPD.aura[unit][b].remain end)
	elseif SPD.db.profile.general.bars.sorting == "descending" then
		table.sort(SPD.order[unit], function(a, b) return SPD.aura[unit][a].remain > SPD.aura[unit][b].remain end)
	end
	SPD[unit].auraHasChanged = false
end

-- bar color reseting
function SPD:ResetBarColor(unit)
	local r, g, b = GetColor(SPD.db.profile.layout.bar[unit].color)
	for k = 1, SPD.db.profile.general.frames[unit].maxAura do
		if SPD.F[unit].bar[k].barColorHasChanged then
			SPD.F[unit].bar[k].statusbar:SetBackdropColor(r, g, b)
			SPD.F[unit].bar[k].statusbar:SetStatusBarColor(r, g, b)
		end
	end
end

-- purges SPD.aura between each cycles
function SPD:ClearAuraTable(unit)
	for k in pairs(SPD.aura[unit]) do
		SPD.aura[unit][k].name = ""
		SPD.aura[unit][k].icon = ""
		SPD.aura[unit][k].remain = 0
		SPD.aura[unit][k].duration = 0
		SPD.aura[unit][k].count = 0
	end
end

-- sound playing
function SPD:SoundPlay(unit)
	if SPD.db.profile.general.sounds.enabled and not SPD[unit].hasPlayed then
		PlaySoundFile(SPD[unit].sound, "Master")
		SPD[unit].hasPlayed = true
	end
end

-- on update function
function SPD:OnUpdate(elapsed)
	self.TimeSinceLastUpdate = (self.TimeSinceLastUpdate or 0) + elapsed
	if self.TimeSinceLastUpdate > SPD.db.profile.general.misc.refresh then
		if SPD.spellIsKnown and not SPD.configMode then
			SPD:Scan("target")
			if SPD.db.profile.general.frames.focus.enabled then
				SPD:Scan("focus")
			end
			if not UnitExists("target") and not UnitExists("focus") then
				SPD.F.update:Hide()
				return
			end
		end
		self.TimeSinceLastUpdate = 0
	end
end
