d("GroundMarker: File loaded")
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
	drawDistance = 100,
	fadeDistance = 80,
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
	-- This keeps the marker at the same height as the player
	local markerY = worldY
	
	d("GetMarkerWorldPosition: " .. markerIndex .. " at " .. tostring(markerX) .. ", " .. tostring(markerY) .. ", " .. tostring(markerZ))

	return markerX, markerY, markerZ
end

-- Initialization
function GroundMarker:Initialize()
	d("GroundMarker: Initializing...")
	
	-- Load renderer first to ensure it's available
	local renderer = GroundMarker.Renderer
	if renderer then
		d("GroundMarker: Renderer module loaded")
	else
		d("GroundMarker: WARNING - Renderer module not available")
	end
	
	-- Load saved variables
	self.savedVariables = ZO_SavedVars:NewCharacterIdSettings("GroundMarkerSavedVars", 1, nil, self.defaults)
	d("GroundMarker: Saved variables loaded")

	-- Set default enabled
	if self.savedVariables.enabled == nil then
		self.savedVariables.enabled = true
	end

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
end

function GroundMarker:CreateMarkerControls()
	d("GroundMarker: Creating marker controls")
	for i = 1, 4 do
		local marker = WINDOW_MANAGER:CreateControl("GroundMarker" .. i, GuiRoot, CT_TEXTURE)
		d("GroundMarker: Created marker control " .. i)

		-- Set larger dimensions for easier visibility
		marker:SetDimensions(256, 256)
		-- Position in center of screen initially
		local uiWidth, uiHeight = GuiRoot:GetDimensions()
		marker:SetAnchor(CENTER, GuiRoot, TOPLEFT, uiWidth/2, uiHeight/2)
		
		-- Make sure it's on top of other UI
		marker:SetDrawLevel(100)
		marker:SetDrawLayer(DL_OVERLAY)
		marker:SetDrawTier(DT_HIGH)

		-- Store in table first so UpdateMarkerTexture can use it
		markers[i] = marker

		-- Set initial texture
		self:UpdateMarkerTexture(i)
		d("GroundMarker: Set texture for marker " .. i)
		
		-- Make sure it's visible for testing
		marker:SetHidden(false)
		d("GroundMarker: Made marker " .. i .. " visible")
	end
	d("GroundMarker: Finished creating marker controls")
end

function GroundMarker:UpdateMarkerTexture(markerIndex)
	local marker = markers[markerIndex]
	local settings = self.savedVariables.markers[markerIndex]

	if not marker or not settings then
		d("GroundMarker: UpdateMarkerTexture - Marker or settings missing for index " .. markerIndex)
		return
	end

	-- Set texture based on type (make sure to use absolute file path)
	local addonRootPath = "/Users/juwallace/code/groundMarker"
	local texturePath
	if settings.type == "circle" then
		texturePath = addonRootPath .. "/textures/circle.dds"
	elseif settings.type == "custom" and settings.customTexture ~= "" then
		texturePath = settings.customTexture
	else
		texturePath = addonRootPath .. "/textures/circle.dds"
	end
	
	d("GroundMarker: Setting texture for marker " .. markerIndex .. " to " .. texturePath)
	marker:SetTexture(texturePath)

	-- Set color - make more visible with higher opacity
	local r = settings.color.r
	local g = settings.color.g
	local b = settings.color.b
	local a = 1.0  -- Force full opacity for testing
	marker:SetColor(r, g, b, a)
	d("GroundMarker: Set color for marker " .. markerIndex .. " to " .. r .. ", " .. g .. ", " .. b .. ", " .. a)

	-- Set size - make larger for testing
	local baseSize = 256 * settings.size  -- Double size from 128 to 256 for testing
	marker:SetDimensions(baseSize, baseSize)
	d("GroundMarker: Set size for marker " .. markerIndex .. " to " .. baseSize)
	
	-- Force visibility for debugging
	marker:SetAlpha(1.0)
	marker:SetHidden(false)
end

function GroundMarker:OnUpdate()
	-- Debug every few seconds (avoid spamming)
	local currentTime = GetGameTimeMilliseconds()
	if not self.lastDebugTime or (currentTime - self.lastDebugTime) > 5000 then
		d("GroundMarker: OnUpdate called, enabled = " .. tostring(self.savedVariables.enabled))
		self.lastDebugTime = currentTime
	end

	if not self.savedVariables.enabled then
		-- Hide all markers
		for i = 1, 4 do
			markers[i]:SetHidden(true)
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
	local settings = self.savedVariables.markers[markerIndex]

	if not marker or not settings or not settings.enabled then
		marker:SetHidden(true)
		return
	end

	-- Get marker world position
	local worldX, worldY, worldZ = GetMarkerWorldPosition(markerIndex)
	if not worldX then
		marker:SetHidden(true)
		return
	end

	-- Convert world position to screen position
	local screenX, screenY, isOnScreen
	
	-- Try using standard WorldPositionToGuiRender3DPosition first
	screenX, screenY, isOnScreen = WorldPositionToGuiRender3DPosition(worldX, worldY, worldZ)
	d("WorldPositionToGuiRender3DPosition result: " .. tostring(screenX) .. ", " .. tostring(screenY) .. ", " .. tostring(isOnScreen))

	-- For debugging, try fixed position if conversion failed
	if not isOnScreen or not screenX or not screenY then
		-- Use center of screen for testing
		local uiWidth, uiHeight = GuiRoot:GetDimensions()
		screenX = uiWidth / 2
		screenY = uiHeight / 2
		isOnScreen = true
		d("Marker " .. markerIndex .. " using fallback center position")
	end
	
	-- Add debug output to help troubleshoot
	d("Marker " .. markerIndex .. " position: " .. tostring(screenX) .. ", " .. tostring(screenY) .. ", isOnScreen: " .. tostring(isOnScreen))

	-- Apply position
	marker:ClearAnchors()
	marker:SetAnchor(CENTER, GuiRoot, TOPLEFT, screenX, screenY)

	-- Calculate distance for scaling/fading
	local playerX, _, playerZ = GetUnitWorldPosition("player")
	local distance = math.sqrt((worldX - playerX) ^ 2 + (worldZ - playerZ) ^ 2) / 100 -- Convert to meters

	-- Apply distance-based scaling
	if self.savedVariables.qualityMode == "high" then
		local scale = math.max(0.5, 1 - (distance / self.savedVariables.drawDistance))
		local size = 128 * settings.size * scale
		marker:SetDimensions(size, size)
	end

	-- Apply distance-based fading
	if distance > self.savedVariables.fadeDistance then
		local fadeAlpha = 1
			- (
				(distance - self.savedVariables.fadeDistance)
				/ (self.savedVariables.drawDistance - self.savedVariables.fadeDistance)
			)
		fadeAlpha = math.max(0, math.min(1, fadeAlpha))
		marker:SetAlpha(settings.color.a * fadeAlpha)
	else
		marker:SetAlpha(settings.color.a)
	end

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
