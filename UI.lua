local ADDON, ns = ...

local _G = _G
local ipairs, pcall, floor, format = ipairs, pcall, math.floor, string.format
local GameTooltip = GameTooltip

-- ElvUI uses bigger fonts (its "small" font is 12 instead of 10), so it gets a roomier layout.
local LAYOUT = {
	blizzard = { w = 580, h = 600, row = 22, search = 160, usageY = 70, statY = 88, divY = 106, listTop = 112 },
	elvui    = { w = 720, h = 680, row = 26, search = 200, usageY = 72, statY = 94, divY = 116, listTop = 122 },
}
local lay = LAYOUT.blizzard
local FRAME_W, FRAME_H, ROW_H = lay.w, lay.h, lay.row
local INDENT = 16

-- One line of text for a font string, so it truncates with "..." instead of wrapping.
local function SingleLine(fs)
	local _, size = fs:GetFont()
	fs:SetHeight((size or 12) + 4)
end

local L = {
	TITLE = "AddOn List",
	USAGE = "AddOn Usage",
	TOTAL = "Total Memory: %s",
	LOADED = "Loaded: %d of %d",
	HIGHEST = "Highest: %s (%s)",
	OUT_OF_DATE = "Load out of date AddOns",
	SEARCH = SEARCH or "Search",
	ENABLE_ALL = "Enable All",
	DISABLE_ALL = "Disable All",
	RELOAD = "Reload UI",
	VIEW_AZ = "A-Z List",
	VIEW_CAT = "Categories",
	VERSION = "Version: %s",
	AUTHOR = "Author: %s",
	CATEGORY = "Category: %s",
	DEPS = "Dependencies: %s",
	MEMORY = "Memory: %s",
	DEMAND = ADDON_DEMAND_LOADED or "Only loadable on demand",
	BANNED = "This addon has been disabled. You should install an updated version.",
	SHIFT_HINT = "Shift-click the checkbox to change only this addon, not its sub-addons.",
}

local VIEWS = {
	{ value = "az", text = L.VIEW_AZ },
	{ value = "category", text = L.VIEW_CAT },
}

local TEX = {
	plus = [[Interface\Buttons\UI-PlusButton-Up]],
	minus = [[Interface\Buttons\UI-MinusButton-Up]],
	expandHighlight = [[Interface\Buttons\UI-PlusButton-Hilight]],
}

local UI = {}
ns.UI = UI

local frame, inset, scroll, scrollBar, rows, numRows
local searchBox, outOfDate, viewDropDown, okayButton
local statLeft, statMid, statRight
local trustTextureResult = false

---------------------------------------------------------------------------
-- Small helpers
---------------------------------------------------------------------------

local function SetSize(region, w, h)
	region:SetWidth(w)
	region:SetHeight(h)
end

local iconOK = {}
local function SetIcon(tex, path)
	if not path then
		tex:Hide()
		return
	end
	if iconOK[path] == false then
		tex:Hide()
		return
	end
	local ok = tex:SetTexture(path)
	if trustTextureResult and not ok then
		iconOK[path] = false
		tex:Hide()
		return
	end
	iconOK[path] = true
	tex:Show()
end

local function ViewText(value)
	for _, v in ipairs(VIEWS) do
		if v.value == value then return v.text end
	end
	return L.VIEW_AZ
end

local function StatusText(node)
	if not node.loadable and node.reason then
		return _G["ADDON_" .. node.reason] or node.reason
	end
	if node.enabled and node.lod and not node.loaded then
		return L.DEMAND
	end
end

local function ScrollBy(delta)
	scrollBar:SetValue(scrollBar:GetValue() - delta * ROW_H * 3)
end

---------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------

local function ShowTooltip(row)
	local e = row.entry
	if not e or e.kind ~= "addon" then return end
	local n = e.node

	GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
	if n.security == "BANNED" then
		GameTooltip:SetText(L.BANNED, 1, 0.1, 0.1, 1, true)
		GameTooltip:Show()
		return
	end

	GameTooltip:AddLine(n.title)
	if n.version then GameTooltip:AddLine(format(L.VERSION, n.version), 0.8, 0.8, 0.8) end
	if n.author then GameTooltip:AddLine(format(L.AUTHOR, ns.StripColors(n.author)), 0.8, 0.8, 0.8) end
	if n.category then GameTooltip:AddLine(format(L.CATEGORY, n.category), 0.8, 0.8, 0.8) end
	if n.notes and n.notes ~= "" then
		GameTooltip:AddLine(n.notes, 1, 1, 1, true)
	end

	local deps = { GetAddOnDependencies(n.index) }
	if #deps > 0 then
		GameTooltip:AddLine(format(L.DEPS, table.concat(deps, ", ")), 1, 0.82, 0, true)
	end
	if n.memory then
		GameTooltip:AddLine(format(L.MEMORY, ns.FormatMemory(n.memory)), 0.8, 0.8, 0.8)
	end
	local status = StatusText(n)
	if status then
		GameTooltip:AddLine(status, 1, 0.5, 0.25)
	end
	if #n.children > 0 then
		GameTooltip:AddLine(L.SHIFT_HINT, 0.5, 0.5, 0.5, true)
	end
	GameTooltip:Show()
end

local function HideTooltip()
	GameTooltip:Hide()
end

---------------------------------------------------------------------------
-- Rows
---------------------------------------------------------------------------

local function SetExpandState(btn, collapsed)
	local tex = collapsed and TEX.plus or TEX.minus
	btn:GetNormalTexture():SetTexture(tex)
	btn:GetPushedTexture():SetTexture(tex)
end

local function Row_OnClick(row)
	local e = row.entry
	if not e then return end
	if e.kind == "category" then
		if ns.searching then return end
		ns.db.collapsedCats[e.category] = not ns.db.collapsedCats[e.category] or nil
		UI:Refresh()
	else
		row.check:Click()
	end
end

local function Expand_OnClick(btn)
	local row = btn:GetParent()
	local e = row.entry
	if not e or ns.searching then return end
	if e.kind == "category" then
		ns.db.collapsedCats[e.category] = not ns.db.collapsedCats[e.category] or nil
	else
		local name = e.node.name
		ns.db.collapsedAddons[name] = not ns.db.collapsedAddons[name] or nil
	end
	UI:Refresh()
end

local function Check_OnClick(check)
	local row = check:GetParent()
	local e = row.entry
	if not e or e.kind ~= "addon" then return end
	local on = check:GetChecked() and true or false
	ns:SetNodeEnabled(e.node, on, not IsShiftKeyDown())
	PlaySound(on and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
	UI:Refresh()
	if GameTooltip:IsOwned(row) then ShowTooltip(row) end
end

local function CreateRow(i)
	local row = CreateFrame("Button", "AddonListPlusRow" .. i, inset)
	row:SetHeight(ROW_H)
	row:SetPoint("TOPLEFT", inset, "TOPLEFT", 6, -6 - (i - 1) * ROW_H)
	row:SetPoint("RIGHT", scroll, "RIGHT", 0, 0)
	row:RegisterForClicks("LeftButtonUp")
	row:EnableMouseWheel(true)
	row:SetScript("OnMouseWheel", function(_, delta) ScrollBy(delta) end)
	row:SetScript("OnClick", Row_OnClick)
	row:SetScript("OnEnter", ShowTooltip)
	row:SetScript("OnLeave", HideTooltip)

	local hl = row:CreateTexture(nil, "HIGHLIGHT")
	hl:SetTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
	hl:SetBlendMode("ADD")
	hl:SetAlpha(0.35)
	hl:SetAllPoints()

	local expand = CreateFrame("Button", nil, row)
	SetSize(expand, 16, 16)
	expand:SetNormalTexture(TEX.minus)
	expand:SetPushedTexture(TEX.minus)
	if TEX.expandHighlight then
		expand:SetHighlightTexture(TEX.expandHighlight)
		expand:GetHighlightTexture():SetBlendMode("ADD")
	end
	expand:SetScript("OnClick", Expand_OnClick)
	row.expand = expand

	local check = CreateFrame("CheckButton", "AddonListPlusRow" .. i .. "Check", row, "UICheckButtonTemplate")
	SetSize(check, 24, 24)
	check:SetScript("OnClick", Check_OnClick)
	check:SetScript("OnEnter", function(self) ShowTooltip(self:GetParent()) end)
	check:SetScript("OnLeave", HideTooltip)
	row.check = check

	local icon = row:CreateTexture(nil, "ARTWORK")
	SetSize(icon, 16, 16)
	icon:SetPoint("LEFT", check, "RIGHT", 2, 0)
	row.icon = icon

	-- Status has no fixed width: it grows with its text and the title takes whatever is left.
	local status = row:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
	status:SetJustifyH("RIGHT")
	status:SetPoint("RIGHT", row, "RIGHT", -4, 0)
	row.status = status

	local title = row:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	title:SetJustifyH("LEFT")
	SingleLine(title)
	row.title = title

	return row
end

local function ConfigureCategoryRow(row, e)
	row.check:Hide()
	row.icon:Hide()
	row.status:Hide()

	row.expand:ClearAllPoints()
	row.expand:SetPoint("LEFT", row, "LEFT", 4, 0)
	SetExpandState(row.expand, e.collapsed)
	row.expand:Show()

	row.title:ClearAllPoints()
	row.title:SetPoint("LEFT", row.expand, "RIGHT", 6, 0)
	row.title:SetPoint("RIGHT", row, "RIGHT", -4, 0)
	row.title:SetText(e.category)
	row.title:SetTextColor(1, 0.82, 0)
end

local function ConfigureAddonRow(row, e)
	local n = e.node
	local x = 4 + e.depth * INDENT

	if #n.children > 0 then
		row.expand:ClearAllPoints()
		row.expand:SetPoint("LEFT", row, "LEFT", x, 0)
		SetExpandState(row.expand, (not ns.searching) and ns.db.collapsedAddons[n.name])
		row.expand:Show()
	else
		row.expand:Hide()
	end

	row.check:ClearAllPoints()
	row.check:SetPoint("LEFT", row, "LEFT", x + 14, 0)
	row.check:SetChecked(n.enabled)
	row.check:Show()

	SetIcon(row.icon, n.icon)

	row.title:ClearAllPoints()
	row.title:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
	row.title:SetPoint("RIGHT", row.status, "LEFT", -10, 0)

	if n.loadable or (n.enabled and (n.reason == "DEMAND_LOADED" or n.reason == "DEP_DEMAND_LOADED")) then
		row.title:SetText(n.title)
		row.title:SetTextColor(1, 0.82, 0)
	elseif n.enabled and n.reason ~= "DEP_DISABLED" then
		row.title:SetText(n.titlePlain)
		row.title:SetTextColor(1, 0.1, 0.1)
	else
		row.title:SetText(n.titlePlain)
		row.title:SetTextColor(0.5, 0.5, 0.5)
	end

	local status = StatusText(n)
	if status then
		row.status:SetText(status)
		row.status:SetTextColor(1, 0.82, 0)
	elseif n.memory then
		row.status:SetText(ns.FormatMemory(n.memory))
		row.status:SetTextColor(0.6, 0.6, 0.6)
	else
		row.status:SetText("")
	end
	row.status:Show()
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------

local rendering
function UI:Render()
	if rendering or not frame then return end
	rendering = true

	local list = ns.display
	FauxScrollFrame_Update(scroll, #list, numRows, ROW_H)
	local offset = FauxScrollFrame_GetOffset(scroll)

	for i = 1, numRows do
		local row = rows[i]
		local e = list[offset + i]
		row.entry = e
		if e then
			if e.kind == "category" then
				ConfigureCategoryRow(row, e)
			else
				ConfigureAddonRow(row, e)
			end
			row:Show()
		else
			row:Hide()
		end
	end

	rendering = false
end

function UI:UpdateUsage()
	statLeft:SetText(format(L.TOTAL, ns.FormatMemory(ns.memTotal or 0)))
	statMid:SetText(format(L.LOADED, ns.memLoaded or 0, #ns.nodes))
	if ns.memTop then
		statRight:SetText(format(L.HIGHEST, ns.memTop.titlePlain, ns.FormatMemory(ns.memTopKB)))
	else
		statRight:SetText("")
	end
end

function UI:UpdateButtons()
	okayButton:SetText(ns:NeedsReload() and L.RELOAD or OKAY)
	if outOfDate:IsShown() then
		outOfDate:SetChecked(ns:IsLoadingOutOfDate())
	end
end

-- Re-read addon states and redraw. resetScroll jumps back to the top (new search or view).
function UI:Refresh(resetScroll)
	if not frame then return end
	ns:UpdateStates()
	ns:BuildDisplay()
	if resetScroll then
		scrollBar:SetValue(0)
	end
	self:Render()
	self:UpdateButtons()
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------

local function CreateButton(name, text, w)
	local b = CreateFrame("Button", name, frame, "UIPanelButtonTemplate")
	SetSize(b, w, 22)
	b:SetText(text)
	return b
end

local function CreateSearchBox()
	local box = CreateFrame("EditBox", "AddonListPlusSearchBox", frame, "InputBoxTemplate")
	SetSize(box, lay.search, 20)
	box:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -38)
	box:SetAutoFocus(false)
	box:SetTextInsets(16, 16, 0, 0)

	local icon = box:CreateTexture(nil, "OVERLAY")
	icon:SetTexture([[Interface\Common\UI-Searchbox-Icon]])
	SetSize(icon, 14, 14)
	icon:SetPoint("LEFT", box, "LEFT", 0, -1)
	icon:SetVertexColor(0.6, 0.6, 0.6)

	local placeholder = box:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
	placeholder:SetPoint("LEFT", box, "LEFT", 17, 0)
	placeholder:SetText(L.SEARCH)

	local clear = CreateFrame("Button", nil, box)
	SetSize(clear, 14, 14)
	clear:SetPoint("RIGHT", box, "RIGHT", -2, 0)
	local clearTex = clear:CreateTexture(nil, "ARTWORK")
	clearTex:SetAllPoints()
	if not clearTex:SetTexture([[Interface\FriendsFrame\ClearBroadcastIcon]]) and trustTextureResult then
		clearTex:Hide()
		local x = clear:CreateFontString(nil, "ARTWORK", "GameFontDisable")
		x:SetPoint("CENTER")
		x:SetText("x")
	end
	clear:SetAlpha(0.6)
	clear:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
	clear:SetScript("OnLeave", function(self) self:SetAlpha(0.6) end)
	clear:SetScript("OnClick", function()
		box:SetText("")
		box:ClearFocus()
	end)
	clear:Hide()

	box:SetScript("OnTextChanged", function(self)
		local text = self:GetText()
		if text == "" then
			placeholder:Show()
			clear:Hide()
		else
			placeholder:Hide()
			clear:Show()
		end
		ns:SetSearch(text)
		UI:Refresh(true)
	end)
	box:SetScript("OnEscapePressed", box.ClearFocus)
	box:SetScript("OnEnterPressed", box.ClearFocus)

	box.icon = icon
	return box
end

local function CreateViewDropDown()
	local dd = CreateFrame("Frame", "AddonListPlusViewDropDown", frame, "UIDropDownMenuTemplate")
	dd:SetPoint("TOPLEFT", frame, "TOPLEFT", 4, -34)
	UIDropDownMenu_SetWidth(dd, 110)

	local function OnSelect(_, value)
		ns.db.view = value
		UIDropDownMenu_SetText(dd, ViewText(value))
		CloseDropDownMenus()
		UI:Refresh(true)
	end

	UIDropDownMenu_Initialize(dd, function(_, level)
		for _, v in ipairs(VIEWS) do
			local info = UIDropDownMenu_CreateInfo()
			info.text = v.text
			info.value = v.value
			info.arg1 = v.value
			info.checked = (ns.db.view == v.value)
			info.func = OnSelect
			UIDropDownMenu_AddButton(info, level)
		end
	end)
	UIDropDownMenu_SetText(dd, ViewText(ns.db.view))
	return dd
end

local function CreateOutOfDateCheck()
	local cb = CreateFrame("CheckButton", "AddonListPlusOutOfDate", frame, "UICheckButtonTemplate")
	SetSize(cb, 24, 24)
	if lay == LAYOUT.elvui then
		-- Sit right after the dropdown so the larger ElvUI text can't run into the search box.
		cb:SetPoint("LEFT", viewDropDown, "RIGHT", 8, 0)
	else
		cb:SetPoint("TOP", frame, "TOP", -78, -36)
	end
	local text = _G[cb:GetName() .. "Text"]
	text:SetText(L.OUT_OF_DATE)
	text:SetFontObject(GameFontNormalSmall)
	cb:SetHitRectInsets(0, -text:GetStringWidth() - 4, 0, 0)
	cb:SetScript("OnClick", function(self)
		ns:SetLoadOutOfDate(self:GetChecked() and true or false)
		PlaySound("igMainMenuOptionCheckBoxOn")
		UI:UpdateButtons()
	end)
	if not ns:HasVersionCheck() then
		cb:Hide()
	end
	return cb
end

local function ApplyElvUISkin(header, title, close, buttons)
	local E, S = ns:GetElvUI()
	if not S then return end

	local function try(fn, ...)
		if fn then pcall(fn, ...) end
	end

	frame:SetBackdrop(nil)
	try(frame.SetTemplate, frame, "Transparent")
	header:Hide()
	title:ClearAllPoints()
	title:SetPoint("TOP", frame, "TOP", 0, -8)

	inset:SetBackdrop(nil)
	try(inset.SetTemplate, inset, "Transparent")

	try(S.HandleCloseButton, S, close, frame)
	try(S.HandleScrollBar, S, scrollBar)
	try(S.HandleEditBox, S, searchBox)
	try(S.HandleDropDownBox, S, viewDropDown, 130)
	try(S.HandleCheckBox, S, outOfDate)
	for _, b in ipairs(buttons) do
		try(S.HandleButton, S, b)
	end
	for _, row in ipairs(rows) do
		try(S.HandleCheckBox, S, row.check)
	end

	local media = E.Media and E.Media.Textures
	if media and media.PlusButton and media.MinusButton then
		TEX.plus, TEX.minus = media.PlusButton, media.MinusButton
		for _, row in ipairs(rows) do
			row.expand:SetHighlightTexture("")
		end
	end
end

function UI:Create()
	if frame then return end

	local _, S = ns:GetElvUI()
	lay = S and LAYOUT.elvui or LAYOUT.blizzard
	FRAME_W, FRAME_H, ROW_H = lay.w, lay.h, lay.row

	frame = CreateFrame("Frame", "AddonListPlusFrame", UIParent)
	SetSize(frame, FRAME_W, FRAME_H)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetToplevel(true)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
	frame:Hide()
	tinsert(UISpecialFrames, "AddonListPlusFrame")

	-- Some clients don't report whether a texture loaded; only trust the result if a known texture reports success.
	local probe = frame:CreateTexture()
	trustTextureResult = probe:SetTexture([[Interface\Buttons\WHITE8X8]]) and true or false
	probe:Hide()

	frame:SetBackdrop({
		bgFile = [[Interface\DialogFrame\UI-DialogBox-Background-Dark]],
		edgeFile = [[Interface\DialogFrame\UI-DialogBox-Border]],
		tile = true, tileSize = 32, edgeSize = 32,
		insets = { left = 11, right = 12, top = 12, bottom = 11 },
	})

	local header = frame:CreateTexture(nil, "ARTWORK")
	header:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
	SetSize(header, 256, 64)
	header:SetPoint("TOP", frame, "TOP", 0, 12)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	title:SetPoint("TOP", header, "TOP", 0, -14)
	title:SetText(L.TITLE)

	local close = CreateFrame("Button", "AddonListPlusFrameClose", frame, "UIPanelCloseButton")
	close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)

	-- Top row
	viewDropDown = CreateViewDropDown()
	outOfDate = CreateOutOfDateCheck()
	searchBox = CreateSearchBox()

	-- Usage
	local usage = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	usage:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -lay.usageY)
	usage:SetText(L.USAGE)

	-- Left and middle size to their text; the right one fills what's left and truncates, so they never overlap.
	statLeft = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	statLeft:SetPoint("TOPLEFT", frame, "TOPLEFT", 24, -lay.statY)
	statMid = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	statMid:SetPoint("TOPLEFT", statLeft, "TOPRIGHT", 40, 0)
	statRight = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
	statRight:SetPoint("TOPLEFT", statMid, "TOPRIGHT", 40, 0)
	statRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -lay.statY)
	statRight:SetJustifyH("RIGHT")
	SingleLine(statRight)

	local divider = frame:CreateTexture(nil, "ARTWORK")
	divider:SetTexture(1, 1, 1, 0.15)
	divider:SetHeight(1)
	divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 22, -lay.divY)
	divider:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -22, -lay.divY)

	-- List
	inset = CreateFrame("Frame", "AddonListPlusInset", frame)
	inset:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -lay.listTop)
	inset:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 42)
	inset:SetBackdrop({
		bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
		edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
		tile = true, tileSize = 16, edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	inset:SetBackdropColor(0, 0, 0, 0.5)
	inset:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
	inset:EnableMouseWheel(true)
	inset:SetScript("OnMouseWheel", function(_, delta) ScrollBy(delta) end)

	scroll = CreateFrame("ScrollFrame", "AddonListPlusScrollFrame", inset, "FauxScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", inset, "TOPLEFT", 4, -6)
	scroll:SetPoint("BOTTOMRIGHT", inset, "BOTTOMRIGHT", -26, 6)
	scroll:SetScript("OnVerticalScroll", function(self, offset)
		FauxScrollFrame_OnVerticalScroll(self, offset, ROW_H, function() UI:Render() end)
	end)
	scrollBar = _G["AddonListPlusScrollFrameScrollBar"]

	local listHeight = FRAME_H - lay.listTop - 42
	numRows = floor((listHeight - 12) / ROW_H)
	rows = {}
	for i = 1, numRows do
		rows[i] = CreateRow(i)
	end

	-- Bottom buttons
	local enableAll = CreateButton("AddonListPlusEnableAll", L.ENABLE_ALL, 120)
	enableAll:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 16, 14)
	enableAll:SetScript("OnClick", function()
		ns:EnableAll()
		UI:Refresh()
	end)

	local disableAll = CreateButton("AddonListPlusDisableAll", L.DISABLE_ALL, 120)
	disableAll:SetPoint("LEFT", enableAll, "RIGHT", 4, 0)
	disableAll:SetScript("OnClick", function()
		ns:DisableAll()
		UI:Refresh()
	end)

	local cancel = CreateButton("AddonListPlusCancel", CANCEL, 90)
	cancel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -16, 14)
	cancel:SetScript("OnClick", function() frame:Hide() end)

	okayButton = CreateButton("AddonListPlusOkay", OKAY, 90)
	okayButton:SetPoint("RIGHT", cancel, "LEFT", -4, 0)
	okayButton:SetScript("OnClick", function()
		frame.committed = true
		if ns:NeedsReload() then
			ReloadUI()
		else
			frame:Hide()
		end
	end)

	ApplyElvUISkin(header, title, close, { enableAll, disableAll, cancel, okayButton })

	-- Show / hide: Cancel, X and Escape undo changes made since opening, like the modern client.
	frame:SetScript("OnShow", function(self)
		ns:BuildStatic()
		ns:BeginEdit()
		self.committed = false
		self.elapsed = 0
		ns:UpdateMemory()
		UI:UpdateUsage()
		UI:Refresh(true)
		PlaySound("igMainMenuOption")
	end)
	frame:SetScript("OnHide", function(self)
		searchBox:ClearFocus()
		if not self.committed then
			ns:RevertEdit()
		end
		PlaySound("igMainMenuClose")
	end)
	frame:SetScript("OnUpdate", function(self, elapsed)
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 5 then
			self.elapsed = 0
			ns:UpdateMemory()
			UI:UpdateUsage()
			UI:Render()
		end
	end)
end

---------------------------------------------------------------------------
-- Public
---------------------------------------------------------------------------

function ns:Show()
	UI:Create()
	frame:Show()
end

function ns:Hide()
	if frame then frame:Hide() end
end

function ns:Toggle()
	if frame and frame:IsShown() then
		frame:Hide()
	else
		self:Show()
	end
end
