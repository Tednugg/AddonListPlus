local _, ns = ...

-- Icons for well-known addons. Addons without one (or with a missing file) show a question mark.
-- Keys are addon folder names in lower case, with leading "!" and "_" removed.
-- Sub-addons (DBM-Naxx, ElvUI_OptionsUI, ...) inherit their parent's icon, so only roots need an entry.
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
