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

	-- Get forward vector - use camera heading for proper orientation in front of player
	local heading = GetPlayerCameraHeading()
	local forwardX = math.sin(heading)
	local forwardZ = math.cos(heading)
	
	-- Calculate marker position in world coordinates
	local distance = marker.distance * 100 -- Convert meters to centimeters
	local markerX = worldX + (forwardX * distance)
	local markerZ = worldZ + (forwardZ * distance)
	
	-- Use player Y position for height (ground level)
	-- Offset slightly lower to ensure it's on the ground
	local markerY = worldY - 10 -- Offset 10cm below player to ensure it's on the ground
	
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
end

function GroundMarker:CreateMarkerControls()
	-- Create markers
	for i = 1, 4 do
		-- Create a topLevelControl to hold the marker
		local container = WINDOW_MANAGER:CreateTopLevelWindow("GroundMarkerContainer" .. i)
		container:SetClampedToScreen(true)
		container:SetDrawLayer(DL_OVERLAY)
		container:SetDrawTier(DT_HIGH)
		container:SetDrawLevel(5000 + i) -- High draw level
		container:SetDimensions(128, 128)
		
		-- Create the texture control inside the container
		local marker = WINDOW_MANAGER:CreateControl("GroundMarker" .. i, container, CT_TEXTURE)
		
		-- Set default properties
		marker:SetAnchorFill(container) -- Fill the container
		marker:SetColor(1, 0, 0, 0.7) -- Default color
		
		-- Hide by default until positioned
		container:SetHidden(true)
		
		-- Store in markers table
		markers[i] = marker
		self["markerContainer" .. i] = container
		
		-- Set initial texture based on settings
		self:UpdateMarkerTexture(i)
	end
end


function GroundMarker:UpdateMarkerTexture(markerIndex)
	local marker = markers[markerIndex]
	local settings = self.savedVariables.markers[markerIndex]

	if not marker or not settings then
		return
	end

	-- Set texture based on type
	local texturePath
	
	-- Try different paths for the texture
	if settings.type == "circle" then
		-- Use a known circle texture from game UI if possible
		texturePath = "GroundMarker/textures/circle.dds"
		-- Fallback to a known circle texture from ESO UI
		if not marker:SetTexture(texturePath) then
			texturePath = "/esoui/art/buttons/gamepad/pointsminus_up.dds" -- Round button texture
		end
	elseif settings.type == "x" then
		texturePath = "GroundMarker/textures/x.dds"
		-- Fallback to a known X texture from ESO UI
		if not marker:SetTexture(texturePath) then
			texturePath = "/esoui/art/buttons/decline_up.dds" -- X button texture
		end
	elseif settings.type == "custom" and settings.customTexture ~= "" then
		texturePath = settings.customTexture
	else
		-- Use a very visible default
		texturePath = "/esoui/art/icons/mapkey/mapkey_groupboss.dds"
	end
	
	-- Set the texture
	marker:SetTexture(texturePath)
	
	-- Apply projection effect - make it appear to be lying flat on the ground
	-- We do this by "squashing" the Y dimension to simulate perspective
	-- This is a common technique to fake 3D ground markers in 2D UI systems
	if settings.type == "circle" then
		-- For circles, we can use a special technique to make them appear flat on ground
		-- Set aspect ratio to make it look like it's projected onto the ground
		local container = GroundMarker["markerContainer" .. markerIndex]
		if container then
			container:SetScale(1.0, 0.5) -- Squash Y axis to create 3D ground projection effect
		end
	end
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

	-- Get marker world position - this is the 3D position in the world
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
	
	-- Properly position the marker on screen
	-- The worldPosition to screen conversion gives us coordinates relative to TOPLEFT of screen
	container:SetAnchor(CENTER, GuiRoot, TOPLEFT, screenX, screenY)
	
	-- Calculate distance from player for scaling
	local _, playerX, playerY, playerZ = GetUnitWorldPosition("player")
	local distanceToMarker = math.sqrt(
		(worldX - playerX)^2 + 
		(worldY - playerY)^2 + 
		(worldZ - playerZ)^2) / 100 -- Convert to meters
	
	-- Calculate size based on distance - apply perspective scaling
	-- The further away, the smaller it appears (simulating 3D perspective)
	local baseSize = 128 * settings.size
	local perspectiveScale = 1.0
	
	-- Apply non-linear perspective scaling based on distance
	if distanceToMarker > 1 then -- More than 1 meter away
		perspectiveScale = 1 / (distanceToMarker * 0.1)
		perspectiveScale = math.max(0.2, math.min(1.5, perspectiveScale)) -- Clamp to reasonable range
	end
	
	local size = baseSize * perspectiveScale
	container:SetDimensions(size, size)
	
	-- Adjust alpha based on distance too - more distant markers are more transparent
	local alphaScale = 1.0
	if distanceToMarker > 10 then -- More than 10 meters away
		alphaScale = 1 - ((distanceToMarker - 10) / 40) -- Linear fade over 40m
		alphaScale = math.max(0.3, alphaScale) -- Don't go fully transparent
	end
	
	-- Apply color with distance-adjusted alpha
	marker:SetColor(settings.color.r, settings.color.g, settings.color.b, settings.color.a * alphaScale)

	-- Apply rotation - align with ground
	-- For ground markers, typically we want them to lie flat, not rotate with camera
	marker:SetTextureRotation(0)
	if settings.rotateWithPlayer then
		local heading = GetPlayerCameraHeading()
		marker:SetTextureRotation(heading)
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
