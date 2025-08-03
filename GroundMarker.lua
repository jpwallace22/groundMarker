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
		-- Create marker control directly - no container hierarchy
		local marker = WINDOW_MANAGER:CreateControl("GroundMarker" .. i, GuiRoot, CT_TEXTURE)
		
		-- Set proper draw layer and level
		marker:SetDrawLayer(DL_OVERLAY)
		marker:SetDrawTier(DT_HIGH)
		marker:SetDrawLevel(100)
		
		-- Set dimensions
		marker:SetDimensions(128, 128)
		
		-- Hide initially
		marker:SetHidden(true)
		
		-- Store in markers table
		markers[i] = marker
		
		-- Set marker texture based on settings
		local settings = self.savedVariables.markers[i]
		if settings then
			-- Determine texture based on type
			local texturePath = "GroundMarker/textures/circle.dds"  -- Default texture
			
			if settings.type == "custom" and settings.customTexture ~= "" then
				texturePath = settings.customTexture
			end
			
			-- Apply texture
			marker:SetTexture(texturePath)
			
			-- Apply color from settings
			marker:SetColor(settings.color.r, settings.color.g, settings.color.b, settings.color.a)
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
	local settings = self.savedVariables.markers[markerIndex]

	-- Make sure we have all the objects we need
	if not marker or not settings or not settings.enabled then
		if marker then marker:SetHidden(true) end
		return
	end

	-- Get player position and heading
	local zone, px, py, pz = GetUnitWorldPosition("player")
	local heading = GetPlayerCameraHeading()
	
	-- Calculate marker position in front of player
	local dist = settings.distance * 100 -- Convert meters to cm
	local mx = px + math.sin(heading) * dist
	local my = py
	local mz = pz + math.cos(heading) * dist
	
	-- Convert world position to screen position
	local x, y, onScreen = WorldPositionToGuiRender3DPosition(mx, my, mz)
	
	-- If marker is not on screen, hide it
	if not onScreen then
		marker:SetHidden(true)
		return
	end
	
	-- Position marker at the calculated screen position
	marker:ClearAnchors()
	marker:SetAnchor(CENTER, GuiRoot, TOPLEFT, x, y)
	
	-- Set size based on settings and distance
	local size = 128 * settings.size
	marker:SetDimensions(size, size)
	
	-- Apply color
	marker:SetColor(settings.color.r, settings.color.g, settings.color.b, settings.color.a)
	
	-- Apply rotation if enabled
	if settings.rotateWithPlayer then
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
	
	-- Make marker visible
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
