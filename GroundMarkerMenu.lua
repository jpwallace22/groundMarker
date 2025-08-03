function GroundMarker:CreateSettingsMenu()
	local LAM = LibAddonMenu2
	if not LAM then
		return
	end

	local panelData = {
		type = "panel",
		name = "Ground Marker",
		displayName = "Ground Marker Settings",
		author = self.author,
		version = self.version,
		slashCommand = "/gmsettings",
		registerForRefresh = true,
		registerForDefaults = true,
	}

	self.settingsPanel = LAM:RegisterAddonPanel(self.name .. "Panel", panelData)

	local optionsData = {
		{
			type = "header",
			name = "General Settings",
		},
		{
			type = "checkbox",
			name = "Enable Ground Markers",
			tooltip = "Master toggle for all ground markers",
			getFunc = function()
				return self.savedVariables.enabled
			end,
			setFunc = function(value)
				self.savedVariables.enabled = value
			end,
			width = "full",
		},
		{
			type = "slider",
			name = "Update Frequency",
			tooltip = "How often markers update their position (in seconds)",
			min = 0.01,
			max = 0.5,
			step = 0.01,
			decimals = 2,
			getFunc = function()
				return self.savedVariables.updateFrequency
			end,
			setFunc = function(value)
				self.savedVariables.updateFrequency = value
				EVENT_MANAGER:UnregisterForUpdate(self.name .. "Update")
				EVENT_MANAGER:RegisterForUpdate(self.name .. "Update", value * 1000, function()
					self:OnUpdate()
				end)
			end,
			width = "full",
		},
		{
			type = "dropdown",
			name = "Quality Mode",
			tooltip = "High quality provides smoother scaling but may impact performance",
			choices = { "high", "low" },
			getFunc = function()
				return self.savedVariables.qualityMode
			end,
			setFunc = function(value)
				self.savedVariables.qualityMode = value
			end,
			width = "full",
		},
		{
			type = "slider",
			name = "Draw Distance",
			tooltip = "Maximum distance to render markers (in meters)",
			min = 50,
			max = 200,
			step = 10,
			getFunc = function()
				return self.savedVariables.drawDistance
			end,
			setFunc = function(value)
				self.savedVariables.drawDistance = value
			end,
			width = "full",
		},
		{
			type = "slider",
			name = "Fade Distance",
			tooltip = "Distance at which markers start fading (in meters)",
			min = 30,
			max = 150,
			step = 10,
			getFunc = function()
				return self.savedVariables.fadeDistance
			end,
			setFunc = function(value)
				self.savedVariables.fadeDistance = value
			end,
			width = "full",
		},
	}

	-- Add settings for each marker
	for i = 1, 4 do
		table.insert(optionsData, {
			type = "header",
			name = "Marker " .. i .. " Settings",
		})

		table.insert(optionsData, {
			type = "checkbox",
			name = "Enable Marker " .. i,
			tooltip = "Toggle this specific marker",
			getFunc = function()
				return self.savedVariables.markers[i].enabled
			end,
			setFunc = function(value)
				self.savedVariables.markers[i].enabled = value
			end,
			width = "full",
		})

		table.insert(optionsData, {
			type = "slider",
			name = "Distance",
			tooltip = "Distance from player in meters",
			min = 1,
			max = 50,
			step = 1,
			getFunc = function()
				return self.savedVariables.markers[i].distance
			end,
			setFunc = function(value)
				self.savedVariables.markers[i].distance = value
			end,
			width = "full",
			disabled = function()
				return not self.savedVariables.markers[i].enabled
			end,
		})

		table.insert(optionsData, {
			type = "dropdown",
			name = "Marker Type",
			tooltip = "Visual style of the marker",
			choices = { "circle", "custom" },
			getFunc = function()
				return self.savedVariables.markers[i].type
			end,
			setFunc = function(value)
				self.savedVariables.markers[i].type = value
				self:UpdateMarkerTexture(i)
			end,
			width = "full",
			disabled = function()
				return not self.savedVariables.markers[i].enabled
			end,
		})

		table.insert(optionsData, {
			type = "colorpicker",
			name = "Marker Color",
			tooltip = "Color and transparency of the marker",
			getFunc = function()
				local c = self.savedVariables.markers[i].color
				return c.r, c.g, c.b, c.a
			end,
			setFunc = function(r, g, b, a)
				self.savedVariables.markers[i].color = { r = r, g = g, b = b, a = a }
				self:UpdateMarkerTexture(i)
			end,
			width = "full",
			disabled = function()
				return not self.savedVariables.markers[i].enabled
			end,
		})

		table.insert(optionsData, {
			type = "slider",
			name = "Marker Size",
			tooltip = "Scale multiplier for the marker",
			min = 0.5,
			max = 3.0,
			step = 0.1,
			decimals = 1,
			getFunc = function()
				return self.savedVariables.markers[i].size
			end,
			setFunc = function(value)
				self.savedVariables.markers[i].size = value
				self:UpdateMarkerTexture(i)
			end,
			width = "full",
			disabled = function()
				return not self.savedVariables.markers[i].enabled
			end,
		})

		table.insert(optionsData, {
			type = "checkbox",
			name = "Pulse Effect",
			tooltip = "Enable pulsing animation",
			getFunc = function()
				return self.savedVariables.markers[i].pulseEnabled
			end,
			setFunc = function(value)
				self.savedVariables.markers[i].pulseEnabled = value
			end,
			width = "full",
			disabled = function()
				return not self.savedVariables.markers[i].enabled
			end,
		})

		table.insert(optionsData, {
			type = "checkbox",
			name = "Rotate With Player",
			tooltip = "Marker rotates with camera heading",
			getFunc = function()
				return self.savedVariables.markers[i].rotateWithPlayer
			end,
			setFunc = function(value)
				self.savedVariables.markers[i].rotateWithPlayer = value
			end,
			width = "full",
			disabled = function()
				return not self.savedVariables.markers[i].enabled
			end,
		})
	end

	LAM:RegisterOptionControls(self.name .. "Panel", optionsData)
end
