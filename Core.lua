local ADDON, ns = ...

local _G = _G
local pairs, ipairs, type, select, pcall, tostring = pairs, ipairs, type, select, pcall, tostring
local tinsert, tsort, wipe = table.insert, table.sort, wipe
local strlower, strfind, strsub, strmatch, gsub, format = string.lower, string.find, string.sub, string.match, string.gsub, string.format

local GetNumAddOns, GetAddOnInfo, GetAddOnMetadata = GetNumAddOns, GetAddOnInfo, GetAddOnMetadata
local GetAddOnDependencies, IsAddOnLoaded, IsAddOnLoadOnDemand = GetAddOnDependencies, IsAddOnLoaded, IsAddOnLoadOnDemand
local EnableAddOn, DisableAddOn = EnableAddOn, DisableAddOn

ns.nodes = {}      -- every addon, by index
ns.roots = {}      -- addons without a parent
ns.byName = {}     -- lower-case folder name -> node

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function StripColors(s)
	if not s then return "" end
	s = gsub(s, "|c%x%x%x%x%x%x%x%x", "")
	s = gsub(s, "|r", "")
	return s
end
ns.StripColors = StripColors

-- GetAddOnMetadata only knows some fields on 3.3.5, so never let it error.
local function Meta(index, field)
	local ok, value = pcall(GetAddOnMetadata, index, field)
	if ok and type(value) == "string" and value ~= "" then
		return value
	end
end
ns.Meta = Meta

-- "!BugGrabber" -> "buggrabber", "_NPCScan.Overlay" -> "npcscan.overlay"
local function StripName(name)
	return (gsub(strlower(name), "^[!_]+", ""))
end

-- "dbm-naxx" -> "dbm", "elvui_optionsui" -> "elvui", "weakaurasoptions" -> "weakaurasoptions"
local function BaseName(stripped)
	return strmatch(stripped, "^([^%-_%.%s]+)") or stripped
end

local function Bool(v) return v and true or false end

function ns.FormatMemory(kb)
	if not kb then return "" end
	if kb >= 1024 then
		return format("%.1f MB", kb / 1024)
	end
	return format("%.0f KB", kb)
end

---------------------------------------------------------------------------
-- Static addon info (names, tree, categories, icons). Built once per session,
-- because the set of installed addons can't change without a restart.
---------------------------------------------------------------------------

local function NormalizeCategory(raw)
	if not raw then return end
	local low = strlower(raw)
	for _, pair in ipairs(ns.CategoryKeywords) do
		if strfind(low, pair[1], 1, true) then
			return pair[2]
		end
	end
	return (gsub(raw, "^%s*(.-)%s*$", "%1"))
end

local function IsAncestor(candidate, node)
	-- true if node is candidate or one of candidate's parents
	local guard = 0
	while candidate and guard < 50 do
		if candidate == node then return true end
		candidate = candidate.parent
		guard = guard + 1
	end
	return false
end

local function FindParent(node, familyRoot)
	-- 1. Explicit group tag
	local group = Meta(node.index, "X-Group") or Meta(node.index, "Group")
	if group then
		local p = ns.byName[strlower(group)]
		if p and p ~= node then return p end
	end

	-- 2. Same name family: DBM-Naxx -> DBM-Core, ElvUI_Enhanced -> ElvUI, Bagnon_Forever -> Bagnon
	local base = BaseName(node.stripped)
	if node.stripped ~= base then
		local root = familyRoot[base]
		if root and root ~= node then return root end
	end

	-- 3. Required dependency whose name starts this addon's name: WeakAurasOptions -> WeakAuras
	local best
	for i = 1, select("#", GetAddOnDependencies(node.index)) do
		local dep = select(i, GetAddOnDependencies(node.index))
		local p = dep and ns.byName[strlower(dep)]
		if p and p ~= node then
			local ds = p.stripped
			if #ds >= 3 and #ds < #node.stripped and strsub(node.stripped, 1, #ds) == ds then
				if not best or #ds < #best.stripped then
					best = p
				end
			end
		end
	end
	return best
end

local function SortNodes(a, b)
	if a.sortKey == b.sortKey then
		return a.name < b.name
	end
	return a.sortKey < b.sortKey
end
ns.SortNodes = SortNodes

function ns:BuildStatic()
	if self.built then return end
	self.built = true

	local nodes, byName = self.nodes, self.byName

	for i = 1, GetNumAddOns() do
		local name, title, notes = GetAddOnInfo(i)
		if name then
			local plain = StripColors(title or name)
			if plain == "" then plain = name end
			local node = {
				index = i,
				name = name,
				title = title or name,
				titlePlain = plain,
				sortKey = strlower(plain),
				notes = notes,
				stripped = StripName(name),
				author = Meta(i, "Author"),
				version = Meta(i, "Version"),
				children = {},
			}
			nodes[#nodes + 1] = node
			byName[strlower(name)] = node
		end
	end

	-- Family roots: an addon named exactly like the family ("bagnon"), or "<family>-core" ("dbm-core")
	local familyRoot = {}
	for _, node in ipairs(nodes) do
		local s = node.stripped
		local core = strmatch(s, "^(.-)[%-_%. ]core$")
		if core and core ~= "" and not familyRoot[core] then
			familyRoot[core] = node
		end
	end
	for _, node in ipairs(nodes) do
		familyRoot[node.stripped] = node -- exact name wins over "-core"
	end

	-- Parents
	for _, node in ipairs(nodes) do
		local p = FindParent(node, familyRoot)
		if p and not IsAncestor(p, node) then
			node.parent = p
			tinsert(p.children, node)
		end
	end

	wipe(self.roots)
	for _, node in ipairs(nodes) do
		if not node.parent then
			tinsert(self.roots, node)
		end
		tsort(node.children, SortNodes)
	end
	tsort(self.roots, SortNodes)

	-- Categories (roots decide, children follow their root)
	local function ChildTag(node)
		for _, c in ipairs(node.children) do
			local tag = Meta(c.index, "X-Category") or ChildTag(c)
			if tag then return tag end
		end
	end
	for _, root in ipairs(self.roots) do
		local cat = NormalizeCategory(Meta(root.index, "Category"))
			or self.BuiltinCategory[root.stripped]
			or NormalizeCategory(Meta(root.index, "X-Category"))
			or NormalizeCategory(ChildTag(root))
			or self.OTHER
		root.category = cat
	end

	-- Icons, category inheritance and search text
	local function Finish(node, parent)
		if parent then
			node.category = parent.category
		end
		node.icon = Meta(node.index, "IconTexture") or Meta(node.index, "X-IconTexture") or Meta(node.index, "X-Icon")
			or self.BuiltinIcon[node.stripped]
			or (parent and parent.icon)
		node.search = strlower(table.concat({
			node.titlePlain, node.name, StripColors(node.notes), node.author or "", node.category or "",
		}, "\n"))
		for _, c in ipairs(node.children) do
			Finish(c, node)
		end
	end
	for _, root in ipairs(self.roots) do
		Finish(root)
	end
end

---------------------------------------------------------------------------
-- Live state
---------------------------------------------------------------------------

function ns:UpdateStates()
	for _, node in ipairs(self.nodes) do
		local _, _, _, enabled, loadable, reason, security = GetAddOnInfo(node.index)
		node.enabled = Bool(enabled)
		node.loadable = Bool(loadable)
		node.reason = reason
		node.security = security
		node.loaded = Bool(IsAddOnLoaded(node.index))
		node.lod = Bool(IsAddOnLoadOnDemand(node.index))
	end
end

function ns:UpdateMemory()
	UpdateAddOnMemoryUsage()
	local total, loaded, top, topKB = 0, 0, nil, 0
	for _, node in ipairs(self.nodes) do
		if IsAddOnLoaded(node.index) then
			local kb = GetAddOnMemoryUsage(node.index) or 0
			node.memory = kb
			total = total + kb
			loaded = loaded + 1
			if kb > topKB then
				top, topKB = node, kb
			end
		else
			node.memory = nil
		end
	end
	self.memTotal, self.memLoaded, self.memTop, self.memTopKB = total, loaded, top, topKB
end

-- "Load out of date AddOns" lives in the checkAddonVersion setting on 3.3.5
function ns:HasVersionCheck()
	local ok, v = pcall(GetCVar, "checkAddonVersion")
	return ok and v ~= nil
end

function ns:IsLoadingOutOfDate()
	local ok, v = pcall(GetCVar, "checkAddonVersion")
	return ok and v == "0"
end

function ns:SetLoadOutOfDate(on)
	SetCVar("checkAddonVersion", on and "0" or "1")
end

local function Snapshot(into)
	wipe(into)
	for i = 1, GetNumAddOns() do
		local _, _, _, enabled = GetAddOnInfo(i)
		into[i] = Bool(enabled)
	end
end

ns.sessionState = {} -- what was enabled when the UI loaded
ns.openState = {}    -- what was enabled when the window was opened (for Cancel)

-- True when the current choices can only take effect after a reload.
function ns:NeedsReload()
	if self.sessionOutOfDate ~= nil and self.sessionOutOfDate ~= self:IsLoadingOutOfDate() then
		return true
	end
	for i = 1, GetNumAddOns() do
		local _, _, _, enabled = GetAddOnInfo(i)
		local was = self.sessionState[i]
		if was ~= nil and Bool(enabled) ~= was then
			-- Load-on-demand addons that aren't running yet don't need a reload either way.
			if IsAddOnLoaded(i) or not IsAddOnLoadOnDemand(i) then
				return true
			end
		end
	end
	return false
end

function ns:BeginEdit()
	Snapshot(self.openState)
	self.openOutOfDate = self:IsLoadingOutOfDate()
end

function ns:RevertEdit()
	for i, enabled in pairs(self.openState) do
		local _, _, _, now = GetAddOnInfo(i)
		if Bool(now) ~= enabled then
			if enabled then EnableAddOn(i) else DisableAddOn(i) end
		end
	end
	if self:HasVersionCheck() and self.openOutOfDate ~= nil and self.openOutOfDate ~= self:IsLoadingOutOfDate() then
		self:SetLoadOutOfDate(self.openOutOfDate)
	end
end

-- Enabling an addon also enables what it needs, so it doesn't end up "Dependency disabled".
local function EnableWithDeps(index, seen)
	seen = seen or {}
	if seen[index] then return end
	seen[index] = true
	EnableAddOn(index)
	for i = 1, select("#", GetAddOnDependencies(index)) do
		local dep = select(i, GetAddOnDependencies(index))
		local node = dep and ns.byName[strlower(dep)]
		if node then
			EnableWithDeps(node.index, seen)
		end
	end
end

function ns:SetNodeEnabled(node, on, includeChildren)
	if on then
		EnableWithDeps(node.index)
	else
		DisableAddOn(node.index)
	end
	if includeChildren then
		for _, c in ipairs(node.children) do
			self:SetNodeEnabled(c, on, true)
		end
	end
end

function ns:EnableAll()
	EnableAllAddOns()
end

function ns:DisableAll()
	DisableAllAddOns()
	EnableAddOn(ADDON) -- keep this list available after the reload
end

---------------------------------------------------------------------------
-- Search
---------------------------------------------------------------------------

ns.tokens = {}

function ns:SetSearch(text)
	wipe(self.tokens)
	for token in strlower(text or ""):gmatch("%S+") do
		tinsert(self.tokens, token)
	end
	self.searching = #self.tokens > 0
end

local function Matches(node, tokens)
	for _, t in ipairs(tokens) do
		if not strfind(node.search, t, 1, true) then
			return false
		end
	end
	return true
end

-- Marks node.visible: it matches, or one of its sub-addons does.
local function MarkVisible(node, tokens, searching)
	local any = false
	for _, c in ipairs(node.children) do
		if MarkVisible(c, tokens, searching) then any = true end
	end
	node.visible = (not searching) or any or Matches(node, tokens)
	return node.visible
end

---------------------------------------------------------------------------
-- Display list: flat rows for the scroll list
---------------------------------------------------------------------------

ns.display = {}

local function AddNode(list, node, depth, db, searching)
	if not node.visible then return end
	tinsert(list, { kind = "addon", node = node, depth = depth })
	if #node.children > 0 and (searching or not db.collapsedAddons[node.name]) then
		for _, c in ipairs(node.children) do
			AddNode(list, c, depth + 1, db, searching)
		end
	end
end

function ns:BuildDisplay()
	local list, db, searching = self.display, self.db, self.searching
	wipe(list)

	for _, root in ipairs(self.roots) do
		MarkVisible(root, self.tokens, searching)
	end

	if db.view == "category" then
		local cats, order = {}, {}
		for _, root in ipairs(self.roots) do
			if root.visible then
				local c = root.category or self.OTHER
				if not cats[c] then
					cats[c] = {}
					tinsert(order, c)
				end
				tinsert(cats[c], root)
			end
		end
		tsort(order, function(a, b)
			if a == self.OTHER then return false end
			if b == self.OTHER then return true end
			return a < b
		end)
		for _, c in ipairs(order) do
			local collapsed = (not searching) and db.collapsedCats[c]
			tinsert(list, { kind = "category", category = c, count = #cats[c], collapsed = collapsed })
			if not collapsed then
				for _, root in ipairs(cats[c]) do
					AddNode(list, root, 1, db, searching)
				end
			end
		end
	else
		for _, root in ipairs(self.roots) do
			AddNode(list, root, 0, db, searching)
		end
	end
end

---------------------------------------------------------------------------
-- Escape menu button
---------------------------------------------------------------------------

local function OpenFromMenu()
	HideUIPanel(GameMenuFrame)
	ns:Show()
end

function ns:GetElvUI()
	if type(_G.ElvUI) ~= "table" or not IsAddOnLoaded("ElvUI") then return end
	local E = _G.ElvUI[1]
	if type(E) ~= "table" or not E.GetModule then return end
	local ok, S = pcall(E.GetModule, E, "Skins", true)
	if ok and S then
		return E, S
	end
end

-- Point other addons' AddOns buttons (ElvUI Enhanced, ACP) and ElvUI Enhanced's list at this window.
function ns:TakeOverOtherButtons()
	local found = false

	for _, btnName in ipairs({ "ElvUI_AddonListButton", "GameMenuButtonAddOns" }) do
		local btn = _G[btnName]
		if btn then
			found = true
			if not btn.alpHooked then
				btn:SetScript("OnClick", OpenFromMenu)
				btn.alpHooked = true
			end
		end
	end

	local elvList = _G.ElvUI_AddonList
	if elvList and not elvList.alpHooked then
		elvList.alpHooked = true
		elvList:HookScript("OnShow", function(f)
			f:Hide()
			ns:Show()
		end)
	end

	return found
end

-- Adds our own AddOns button only when no other addon already did.
function ns:SetupMenuButton()
	if self:TakeOverOtherButtons() then return end
	if self.menuButton then return end

	local logout = GameMenuButtonLogout
	local point, relTo, relPoint, x, y = logout:GetPoint()
	relTo = relTo or GameMenuButtonMacros

	local btn = CreateFrame("Button", "AddonListPlusMenuButton", GameMenuFrame, "GameMenuButtonTemplate")
	btn:SetText(ADDONS or "AddOns")
	btn:SetWidth(logout:GetWidth())
	btn:SetHeight(logout:GetHeight())
	btn:SetScript("OnClick", OpenFromMenu)
	btn:SetPoint("TOP", relTo, "BOTTOM", 0, -1)

	logout:ClearAllPoints()
	logout:SetPoint(point or "TOP", btn, relPoint or "BOTTOM", x or 0, y or -16)
	GameMenuFrame:SetHeight(GameMenuFrame:GetHeight() + btn:GetHeight() + 1)

	local E, S = self:GetElvUI()
	if S and S.HandleButton then
		local skins = E.private and E.private.skins and E.private.skins.blizzard
		if not skins or (skins.enable ~= false and skins.misc ~= false) then
			pcall(S.HandleButton, S, btn)
		end
	end

	self.menuButton = btn
end

---------------------------------------------------------------------------
-- Startup
---------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
	if event == "ADDON_LOADED" and arg1 == ADDON then
		AddonListPlusDB = AddonListPlusDB or {}
		local db = AddonListPlusDB
		db.view = db.view or "az"
		db.collapsedCats = db.collapsedCats or {}
		db.collapsedAddons = db.collapsedAddons or {}
		ns.db = db

		Snapshot(ns.sessionState)
		if ns:HasVersionCheck() then
			ns.sessionOutOfDate = ns:IsLoadingOutOfDate()
		end

		-- Hooked now so it runs before ElvUI's own menu hook, which keeps the order Macros > AddOns > ElvUI.
		GameMenuFrame:HookScript("OnShow", function()
			ns:SetupMenuButton()
		end)
	elseif event == "PLAYER_LOGIN" then
		ns:TakeOverOtherButtons()
	end
end)

SLASH_ADDONLISTPLUS1 = "/addons"
SLASH_ADDONLISTPLUS2 = "/alp"
SlashCmdList.ADDONLISTPLUS = function()
	ns:Toggle()
end
