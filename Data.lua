local _, ns = ...

-- Keys below are addon folder names in lower case, with leading "!" and "_" removed.
-- Sub-addons (DBM-Naxx, ElvUI_OptionsUI, ...) inherit from their parent, so only roots need an entry.

ns.OTHER = "Other"

-- Category for well-known addons. Wins over the addon's own X-Category tag,
-- because old tags are often vague ("Map" for AtlasLoot, "Miscellaneous", ...).
ns.BuiltinCategory = {
	-- Action Bars
	["bartender4"] = "Action Bars", ["dominos"] = "Action Bars", ["omnicc"] = "Action Bars",
	["myslot"] = "Action Bars", ["macaroon"] = "Action Bars", ["autobar"] = "Action Bars",
	["buttonfacade"] = "Action Bars", ["masque"] = "Action Bars",

	-- Auctions
	["auctionator"] = "Auctions", ["auc-advanced"] = "Auctions", ["auctionmaster"] = "Auctions",
	["aux-addon"] = "Auctions", ["tradeskillmaster"] = "Auctions", ["auctionlite"] = "Auctions",

	-- Bags & Inventory
	["bagnon"] = "Bags & Inventory", ["bagnon_forever"] = "Bags & Inventory", ["adibags"] = "Bags & Inventory",
	["arkinventory"] = "Bags & Inventory", ["baggins"] = "Bags & Inventory", ["onebag3"] = "Bags & Inventory",
	["combuctor"] = "Bags & Inventory", ["postal"] = "Bags & Inventory", ["itemrack"] = "Bags & Inventory",
	["outfitter"] = "Bags & Inventory",

	-- Chat & Social
	["bnettoast"] = "Chat & Social", ["prat-3.0"] = "Chat & Social", ["chatter"] = "Chat & Social",
	["wim"] = "Chat & Social",

	-- Class
	["pallypower"] = "Class", ["tankmd"] = "Class", ["whatstraining_wotlk"] = "Class",
	["whatstraining"] = "Class", ["totemtimers"] = "Class", ["necrosis"] = "Class",

	-- Combat
	["details"] = "Combat", ["recount"] = "Combat", ["skada"] = "Combat", ["omen"] = "Combat",
	["weakauras"] = "Combat", ["merfinplus"] = "Combat", ["spellreplay"] = "Combat", ["cl_fix"] = "Combat",
	["simexporter"] = "Combat", ["cheese"] = "Combat", ["quartz"] = "Combat", ["tellmewhen"] = "Combat",
	["powerauras"] = "Combat", ["gtfo"] = "Combat", ["mikscrollingbattletext"] = "Combat",
	["parrot"] = "Combat", ["forte_core"] = "Combat", ["nugrunning"] = "Combat",

	-- Development Tools
	["buggrabber"] = "Development Tools", ["bugsack"] = "Development Tools",
	["apidocumentation"] = "Development Tools", ["details335_devtools"] = "Development Tools",
	["devtools"] = "Development Tools", ["viragedevtool"] = "Development Tools", ["spew"] = "Development Tools",

	-- Dungeons & Raids
	["dbm-core"] = "Dungeons & Raids", ["bigwigs"] = "Dungeons & Raids", ["raidbrowser"] = "Dungeons & Raids",
	["exorsusraidtools"] = "Dungeons & Raids", ["angrymarks"] = "Dungeons & Raids",

	-- Loot
	["atlaslootclassic"] = "Loot", ["atlasloot"] = "Loot", ["raidroll"] = "Loot", ["rclootcouncil"] = "Loot",
	["xloot"] = "Loot", ["epgp"] = "Loot", ["epgp_lootmaster"] = "Loot",

	-- Map & Minimap
	["npcscan"] = "Map & Minimap", ["atlas"] = "Map & Minimap", ["carbonite"] = "Map & Minimap",
	["mapster"] = "Map & Minimap", ["sexymap"] = "Map & Minimap", ["routes"] = "Map & Minimap",
	["tomtom"] = "Map & Minimap", ["handynotes"] = "Map & Minimap",

	-- Media
	["sharedmedia"] = "Media", ["sharedmediaretail"] = "Media", ["sharedmedia_naowh"] = "Media",

	-- Professions
	["gathermate"] = "Professions", ["gathermate2"] = "Professions", ["ackisrecipelist"] = "Professions",
	["skillet"] = "Professions", ["tradeskillinfo"] = "Professions",

	-- PvP
	["gladius"] = "PvP", ["gladiatorlossa"] = "PvP", ["capping"] = "PvP", ["battlegroundtargets"] = "PvP",

	-- Quests & Leveling
	["questie-335"] = "Quests & Leveling", ["questie"] = "Quests & Leveling",
	["zygorguidesviewer"] = "Quests & Leveling", ["questhelper"] = "Quests & Leveling",

	-- Tooltips
	["gearscorelite"] = "Tooltips", ["gearscore"] = "Tooltips", ["tiptac"] = "Tooltips",
	["ratingbuster"] = "Tooltips", ["idtip"] = "Tooltips",

	-- Unit Frames
	["pitbull4"] = "Unit Frames", ["shadowedunitframes"] = "Unit Frames", ["xperl"] = "Unit Frames",
	["grid"] = "Unit Frames", ["grid2"] = "Unit Frames", ["vuhdo"] = "Unit Frames", ["healbot"] = "Unit Frames",
	["clique"] = "Unit Frames", ["tidyplates"] = "Unit Frames", ["aloft"] = "Unit Frames",

	-- User Interface
	["acp"] = "User Interface", ["elvui"] = "User Interface", ["leatrix_plus"] = "User Interface",
	["tukui"] = "User Interface", ["moveanything"] = "User Interface", ["kgpanels"] = "User Interface",
	["titan"] = "User Interface", ["chocolatebar"] = "User Interface", ["addonlistplus"] = "User Interface",
}

-- Turns an addon's own X-Category / Category tag into one of the names above.
-- Checked in order; the first keyword found in the tag wins.
ns.CategoryKeywords = {
	{ "action", "Action Bars" },
	{ "auction", "Auctions" }, { "econom", "Auctions" },
	{ "bag", "Bags & Inventory" }, { "inventory", "Bags & Inventory" }, { "item", "Bags & Inventory" }, { "mail", "Bags & Inventory" },
	{ "boss", "Dungeons & Raids" }, { "raid", "Dungeons & Raids" }, { "dungeon", "Dungeons & Raids" }, { "encounter", "Dungeons & Raids" },
	{ "chat", "Chat & Social" }, { "communication", "Chat & Social" }, { "social", "Chat & Social" }, { "guild", "Chat & Social" },
	{ "develop", "Development Tools" }, { "debug", "Development Tools" }, { "document", "Development Tools" },
	{ "librar", "Libraries" },
	{ "loot", "Loot" },
	{ "minimap", "Map & Minimap" }, { "map", "Map & Minimap" },
	{ "profession", "Professions" }, { "tradeskill", "Professions" }, { "craft", "Professions" }, { "gather", "Professions" },
	{ "quest", "Quests & Leveling" }, { "level", "Quests & Leveling" },
	{ "pvp", "PvP" }, { "arena", "PvP" }, { "battleground", "PvP" },
	{ "tooltip", "Tooltips" },
	{ "unit", "Unit Frames" }, { "nameplate", "Unit Frames" },
	{ "combat", "Combat" }, { "damage", "Combat" }, { "buff", "Combat" }, { "threat", "Combat" }, { "healer", "Combat" },
	{ "warrior", "Class" }, { "paladin", "Class" }, { "hunter", "Class" }, { "rogue", "Class" }, { "priest", "Class" },
	{ "death knight", "Class" }, { "shaman", "Class" }, { "mage", "Class" }, { "warlock", "Class" }, { "druid", "Class" },
	{ "class", "Class" },
	{ "media", "Media" }, { "audio", "Media" }, { "sound", "Media" },
	{ "interface", "User Interface" },
	{ "misc", ns.OTHER },
}

-- Icons for well-known addons. Paths that don't exist simply show an empty slot.
ns.BuiltinIcon = {
	["weakauras"] = [[Interface\AddOns\WeakAuras\Media\Textures\icon]],
	["details"] = [[Interface\AddOns\Details\images\minimap]],
	["bugsack"] = [[Interface\AddOns\BugSack\Media\icon]],
	["buggrabber"] = [[Interface\Icons\INV_Misc_QuestionMark]],
	["gathermate"] = [[Interface\AddOns\GatherMate\Artwork\Icon]],
	["leatrix_plus"] = [[Interface\AddOns\Leatrix_Plus\assets\minimapicon]],
	["merfinplus"] = [[Interface\AddOns\MerfinPlus\Media\icons\merfinui_logo_icon]],
	["zygorguidesviewer"] = [[Interface\AddOns\ZygorGuidesViewer\Skin\zg-logo-on]],
	["dbm-core"] = [[Interface\AddOns\DBM-Core\textures\Minimap-Button-Up]],
	["apidocumentation"] = [[Interface\Icons\INV_Misc_Book_09]],
	["auctionator"] = [[Interface\Icons\INV_Misc_Coin_02]],
	["atlaslootclassic"] = [[Interface\Icons\INV_Box_01]],
	["atlasloot"] = [[Interface\Icons\INV_Box_01]],
	["bagnon"] = [[Interface\Icons\INV_Misc_Bag_07]],
	["pallypower"] = [[Interface\Icons\Spell_Holy_GreaterBlessingofKings]],
	["tankmd"] = [[Interface\Icons\Ability_Hunter_Misdirection]],
	["raidroll"] = [[Interface\Icons\INV_Misc_Dice_01]],
	["gearscorelite"] = [[Interface\Icons\INV_Misc_Gear_01]],
	["gearscore"] = [[Interface\Icons\INV_Misc_Gear_01]],
	["npcscan"] = [[Interface\Icons\INV_Misc_Spyglass_03]],
	["questie-335"] = [[Interface\GossipFrame\AvailableQuestIcon]],
	["questie"] = [[Interface\GossipFrame\AvailableQuestIcon]],
	["bnettoast"] = [[Interface\FriendsFrame\Battlenet-Battleneticon]],
	["omen"] = [[Interface\AddOns\Omen\icon]],
	["skada"] = [[Interface\Icons\Spell_Lightning_LightningBolt01]],
	["bartender4"] = [[Interface\Icons\INV_Drink_05]],
	["addonlistplus"] = [[Interface\Icons\INV_Misc_Gear_02]],
}
