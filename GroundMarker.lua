GroundMarker = {}
GroundMarker.name = "GroundMarker"
GroundMarker.version = "1.0.0"
GroundMarker.author = "jpwallace22"
GroundMarker.defaults = {
	enabled = true,
	markers = {
		[1] = {
			enabled = true,
			distance = 10, -- meters
			type = "circle", -- circle, x, custom
			color = { r = 1, g = 0, b = 0, a = 0.7 },
			size = 1.0,
			pulseEnabled = false,
			rotateWithPlayer = true,
		},
		[2] = {
			enabled = false,
			distance = 20,
			type = "circle",
			color = { r = 0, g = 1, b = 0, a = 0.7 },
			size = 1.0,
			pulseEnabled = false,
			rotateWithPlayer = true,
		},
		[3] = {
			enabled = false,
			distance = 30,
			type = "circle",
			color = { r = 0, g = 0, b = 1, a = 0.7 },
			size = 1.0,
			pulseEnabled = false,
			rotateWithPlayer = true,
		},
		[4] = {
			enabled = false,
			distance = 40,
			type = "circle",
			color = { r = 1, g = 1, b = 0, a = 0.7 },
			size = 1.0,
			pulseEnabled = false,
			rotateWithPlayer = true,
		},
	},
	updateFrequency = 0.05, -- seconds
	qualityMode = "high",
	customTexture = "",
}

-- Local variables
local markers = {}

-- Utility functions
local function GetForwardVector()
	local heading = GetPlayerCameraHeading()
	-- Convert heading to forward vector
	local x = math.sin(heading)
	local z = math.cos(heading)
	return x, z
end

local function GetMarkerWorldPosition(markerIndex)
	local marker = GroundMarker.savedVariables.markers[markerIndex]
	if not marker or not marker.enabled then
		return nil, nil, nil
	end

	-- Get player position
	local zone, worldX, worldY, worldZ = GetUnitWorldPosition("player")

	-- Get forward vector
	local forwardX, forwardZ = GetForwardVector()
	
	-- Calculate marker position
	local distance = marker.distance * 100 -- Convert meters to centimeters
	local markerX = worldX + (forwardX * distance)
	local markerZ = worldZ + (forwardZ * distance)
	
	-- Use player Y position for height (ground level)
	local markerY = worldY

	return markerX, markerY, markerZ
end

-- Initialization
function GroundMarker:Initialize()
	-- Load saved variables
	self.savedVariables = ZO_SavedVars:NewCharacterIdSettings("GroundMarkerSavedVars", 1, nil, self.defaults)
	
	-- Create marker controls
	self:CreateMarkerControls()
	
	-- Register commands
	self:RegisterCommands()
	
	-- Create settings menu
	self:CreateSettingsMenu()
	
	-- Register update handler
	EVENT_MANAGER:RegisterForUpdate(self.name .. "Update", self.savedVariables.updateFrequency * 1000, function()
		self:OnUpdate()
	end)
	
	-- For debugging - run a visibility test after a delay
	zo_callLater(function()
		self:DiagnosticTest()
	end, 5000)
end

-- Diagnostic function to help troubleshoot marker visibility
function GroundMarker:DiagnosticTest()
	-- Get first marker
	local marker = markers[1]
	
	if not marker then
		d("GroundMarker Diagnostic: Marker 1 not initialized!")
		return
	end
	
	-- Check if textures can be loaded
	if not marker:GetTextureFileName() or marker:GetTextureFileName() == "" then
		d("GroundMarker Diagnostic: Texture not loaded!")
	else
		d("GroundMarker Diagnostic: Texture loaded: " .. marker:GetTextureFileName())
	end
	
	-- Check marker dimensions
	local width, height = marker:GetDimensions()
	d("GroundMarker Diagnostic: Marker dimensions: " .. width .. "x" .. height)
	
	-- Check if marker is hidden
	d("GroundMarker Diagnostic: Marker hidden: " .. tostring(marker:IsHidden()))
	
	-- Check visibility settings
	d("GroundMarker Diagnostic: Addon enabled: " .. tostring(self.savedVariables.enabled))
	d("GroundMarker Diagnostic: Marker enabled: " .. tostring(self.savedVariables.markers[1].enabled))
	
	-- Force marker to be visible in center of screen for testing
	marker:ClearAnchors()
	local uiWidth, uiHeight = GuiRoot:GetDimensions()
	marker:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
	marker:SetColor(1, 0, 0, 1)
	marker:SetDimensions(200, 200)
	marker:SetHidden(false)
	d("GroundMarker Diagnostic: Forced marker to center of screen!")
end

function GroundMarker:CreateMarkerControls()
	-- Create markers
	for i = 1, 4 do
		-- Create a topLevelControl to hold the marker
		local container = WINDOW_MANAGER:CreateTopLevelWindow("GroundMarkerContainer" .. i)
		container:SetClampedToScreen(true)
		container:SetDrawLayer(DL_OVERLAY)
		container:SetDrawTier(DT_HIGH)
		container:SetDrawLevel(5000 + i) -- Very high draw level
		container:SetDimensions(200, 200)
		
		-- Create the texture control inside the container
		local marker = WINDOW_MANAGER:CreateControl("GroundMarker" .. i, container, CT_TEXTURE)
		
		-- Set default properties
		marker:SetDimensions(200, 200) -- Larger size
		marker:SetAnchorFill(container) -- Fill the container
		marker:SetColor(1, 0, 0, 1) -- Start with bright red for visibility
		
		-- Make the container visible but center it off-screen initially
		container:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
		container:SetAlpha(1)
		container:SetHidden(false)
		
		-- Store in markers table
		markers[i] = marker
		self["markerContainer" .. i] = container
		
		-- Set initial texture based on settings
		self:UpdateMarkerTexture(i)
		
		-- Make sure the first marker is visible for testing
		if i == 1 then
			marker:SetHidden(false)
			container:SetHidden(false)
		end
	end
	
	d("GroundMarker: Created " .. #markers .. " marker controls")
end


function GroundMarker:UpdateMarkerTexture(markerIndex)
	local marker = markers[markerIndex]
	local settings = self.savedVariables.markers[markerIndex]

	if not marker or not settings then
		return
	end

	-- Set texture based on type - use full absolute path
	-- This is a common issue with ESO textures - paths must be specific
	local addonRootPath = "/esoui/art" -- ESO built-in texture path as fallback
	local texturePath
	
	-- Try different paths for the texture
	if settings.type == "circle" then
		-- Try multiple texture sources
		texturePath = "GroundMarker/textures/circle.dds" -- Standard path
		
		-- Fallback to built-in textures if needed
		if not DoesFileExist(texturePath) then
			texturePath = "/esoui/art/icons/quest_icon_main.dds" -- Built-in circular icon
			d("GroundMarker: Using fallback texture for circle")
		end
	elseif settings.type == "x" then
		texturePath = "GroundMarker/textures/x.dds"
		
		-- Fallback to built-in textures if needed
		if not DoesFileExist(texturePath) then
			texturePath = "/esoui/art/buttons/decline_up.dds" -- Built-in X icon
			d("GroundMarker: Using fallback texture for X")
		end
	elseif settings.type == "custom" and settings.customTexture ~= "" then
		texturePath = settings.customTexture
	else
		texturePath = "/esoui/art/icons/mapkey/mapkey_groupboss.dds" -- Very visible fallback
	end
	
	-- Set the texture and save the path for diagnostic
	marker.texturePath = texturePath
	marker:SetTexture(texturePath)
	
	-- Apply color settings
	marker:SetColor(settings.color.r, settings.color.g, settings.color.b, 1.0) -- Force full opacity
	
	-- Set size based on settings - make it bigger to ensure visibility
	local size = 200 * settings.size
	marker:SetDimensions(size, size)
end

function GroundMarker:OnUpdate()
	if not self.savedVariables.enabled then
		-- Hide all markers if disabled
		for i = 1, 4 do
			if markers[i] then
				markers[i]:SetHidden(true)
			end
		end
		return
	end

	-- Update each marker
	for i = 1, 4 do
		self:UpdateMarker(i)
	end
end

function GroundMarker:UpdateMarker(markerIndex)
	local marker = markers[markerIndex]
	local container = self["markerContainer" .. markerIndex]
	local settings = self.savedVariables.markers[markerIndex]

	-- Make sure we have all the objects we need
	if not marker or not container or not settings or not settings.enabled then
		if container then container:SetHidden(true) end
		return
	end

	-- For debugging, if it's the first marker, always show it in center for testing
	if markerIndex == 1 and not self.initialTestDone then
		container:SetAnchor(CENTER, GuiRoot, CENTER, 0, 0)
		marker:SetColor(1, 0, 0, 1)
		container:SetHidden(false)
		marker:SetHidden(false)
		
		-- Only do this once
		self.initialTestDone = true
		return
	end

	-- Get marker world position
	local worldX, worldY, worldZ = GetMarkerWorldPosition(markerIndex)
	if not worldX then
		container:SetHidden(true)
		return
	end

	-- Convert world position to screen position
	local screenX, screenY, isOnScreen = WorldPositionToGuiRender3DPosition(worldX, worldY, worldZ)

	-- Check if the position is valid and visible on screen
	if not isOnScreen or not screenX or not screenY then
		container:SetHidden(true)
		return
	end

	-- Position the container (which holds the marker)
	container:ClearAnchors()
	container:SetAnchor(CENTER, GuiRoot, TOPLEFT, screenX, screenY)

	-- Set marker size based on settings
	local size = 200 * settings.size
	container:SetDimensions(size, size)
	marker:SetDimensions(size, size)
	
	-- Apply color settings - force full opacity for testing
	marker:SetColor(settings.color.r, settings.color.g, settings.color.b, 1.0)

	-- Apply rotation if enabled
	if settings.rotateWithPlayer then
		local heading = GetPlayerCameraHeading()
		marker:SetTextureRotation(heading)
	else
		marker:SetTextureRotation(0)
	end

	-- Apply pulse effect if enabled
	if settings.pulseEnabled then
		local time = GetGameTimeMilliseconds() / 1000
		local pulse = math.sin(time * 2) * 0.2 + 0.8
		marker:SetAlpha(marker:GetAlpha() * pulse)
	end

	-- Make sure both container and marker are visible
	container:SetHidden(false)
	marker:SetHidden(false)
end

-- Command handlers
function GroundMarker:RegisterCommands()
	local addon = self -- Capture self reference
	SLASH_COMMANDS["/groundmarker"] = function(args)
		addon:OnSlashCommand(args)
	end
	SLASH_COMMANDS["/gm"] = function(args)
		addon:OnSlashCommand(args)
	end
end

function GroundMarker:OnSlashCommand(args)
	local commands = {}
	for word in args:gmatch("%S+") do
		table.insert(commands, word)
	end

	if #commands == 0 then
		-- Toggle main marker
		self.savedVariables.enabled = not self.savedVariables.enabled
		d("Ground Marker " .. (self.savedVariables.enabled and "enabled" or "disabled"))
		return
	end

	local cmd = commands[1]:lower()

	if cmd == "settings" then
		-- Open settings menu
		local LAM = LibAddonMenu2
		if LAM and self.settingsPanel then
			LAM:OpenToPanel(self.settingsPanel)
		else
			d({ "Settings menu not available. Make sure LibAddonMenu2 is installed." })
		end
	elseif cmd == "distance" and commands[2] then
		local distance = tonumber(commands[2])
		if distance and distance >= 1 and distance <= 50 then
			self.savedVariables.markers[1].distance = distance
			d("Ground Marker distance set to " .. distance .. " meters")
		else
			d("Invalid distance. Use a value between 1 and 50")
		end
	elseif cmd == "type" and commands[2] then
		local markerType = commands[2]:lower()
		if markerType == "circle" or markerType == "custom" then
			self.savedVariables.markers[1].type = markerType
			self:UpdateMarkerTexture(1)
			d("Ground Marker type set to " .. markerType)
		else
			d("Invalid type. Use 'circle' or 'custom'")
		end
	elseif cmd == "color" and commands[2] and commands[3] and commands[4] then
		local r = tonumber(commands[2]) / 255
		local g = tonumber(commands[3]) / 255
		local b = tonumber(commands[4]) / 255
		local a = commands[5] and (tonumber(commands[5]) / 255) or 0.7

		if r and g and b then
			self.savedVariables.markers[1].color = { r = r, g = g, b = b, a = a }
			self:UpdateMarkerTexture(1)
			d("Ground Marker color updated")
		else
			d("Invalid color values. Use numbers 0-255 for R G B [A]")
		end
	else
		d("Ground Marker commands:")
		d("  /gm - Toggle marker visibility")
		d("  /gm settings - Open settings menu")
		d("  /gm distance [1-50] - Set marker distance in meters")
		d("  /gm type [circle|x|custom] - Set marker type")
		d("  /gm color [r] [g] [b] [a] - Set color (0-255)")
	end
end

-- API functions for other addons
function GroundMarker:SetMarkerDistance(markerIndex, distance)
	if markerIndex < 1 or markerIndex > 4 then
		return false
	end
	if distance < 1 or distance > 50 then
		return false
	end

	self.savedVariables.markers[markerIndex].distance = distance
	return true
end

function GroundMarker:ToggleMarker(markerIndex)
	if markerIndex < 1 or markerIndex > 4 then
		return false
	end

	local marker = self.savedVariables.markers[markerIndex]
	marker.enabled = not marker.enabled
	return marker.enabled
end

function GroundMarker:SetMarkerColor(markerIndex, r, g, b, a)
	if markerIndex < 1 or markerIndex > 4 then
		return false
	end

	self.savedVariables.markers[markerIndex].color = {
		r = r or 1,
		g = g or 0,
		b = b or 0,
		a = a or 0.7,
	}
	self:UpdateMarkerTexture(markerIndex)
	return true
end

-- Callbacks system
GroundMarker.callbacks = {}

function GroundMarker:RegisterCallback(event, callback)
	if not self.callbacks[event] then
		self.callbacks[event] = {}
	end
	table.insert(self.callbacks[event], callback)
end

function GroundMarker:FireCallbacks(event, ...)
	if self.callbacks[event] then
		for _, callback in ipairs(self.callbacks[event]) do
			callback(...)
		end
	end
end

-- Event handlers
EVENT_MANAGER:RegisterForEvent(GroundMarker.name, EVENT_ADD_ON_LOADED, function(_, addonName)
	d("Addon loaded: " .. addonName)
	if addonName == GroundMarker.name then
		d("GroundMarker: Name matches, initializing...")
		GroundMarker:Initialize()
	end
end)

-- Additional keybind functions
function GroundMarker:ToggleEnabled()
	self.savedVariables.enabled = not self.savedVariables.enabled
	d("Ground Marker " .. (self.savedVariables.enabled and "enabled" or "disabled"))
end

function GroundMarker:CycleMarkerType(markerIndex)
	local types = { "circle", "x", "custom" }
	local current = self.savedVariables.markers[markerIndex].type
	local currentIndex = 1

	for i, t in ipairs(types) do
		if t == current then
			currentIndex = i
			break
		end
	end

	local nextIndex = (currentIndex % #types) + 1
	self.savedVariables.markers[markerIndex].type = types[nextIndex]
	self:UpdateMarkerTexture(markerIndex)
	d("Marker " .. markerIndex .. " type changed to " .. types[nextIndex])
end

function GroundMarker:AdjustDistance(markerIndex, delta)
	local current = self.savedVariables.markers[markerIndex].distance
	local new = math.max(1, math.min(50, current + delta))

	self.savedVariables.markers[markerIndex].distance = new
	d("Marker " .. markerIndex .. " distance: " .. new .. " meters")
end
