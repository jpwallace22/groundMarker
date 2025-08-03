GroundMarker.Renderer = {}

-- Enhanced positioning using OdySupportIcons-style approach
function GroundMarker.Renderer:GetEnhancedScreenPosition(worldX, worldY, worldZ)
	-- Try to use OdySupportIcons if available for better positioning
	if OdySupportIcons and OdySupportIcons.GetScreenPositionFor3DPosition then
		return OdySupportIcons.GetScreenPositionFor3DPosition(worldX, worldY, worldZ)
	end

	-- Fallback to standard API
	local screenX, screenY, isInView = WorldPositionToGuiRender3DPosition(worldX, worldY, worldZ)

	-- Additional depth calculation for better ground alignment
	if isInView then
		-- Use player position for depth calculation
		local _, camX, camY, camZ = GetUnitWorldPosition("player")

		-- Calculate distance from camera
		local dx = worldX - camX
		local dy = worldY - camY
		local dz = worldZ - camZ
		local distance = math.sqrt(dx * dx + dy * dy + dz * dz)

		-- Apply perspective scaling
		local perspectiveScale = 1000 / (distance + 1000)

		return screenX, screenY, isInView, perspectiveScale
	end

	return screenX, screenY, isInView, 1
end

-- Calculate ground height at position (approximation)
function GroundMarker.Renderer:EstimateGroundHeight(worldX, worldZ)
	-- This is a simplified approach - in reality, you'd need terrain data
	-- For now, we'll use the player's Y position as reference
	local _, playerY, _ = GetUnitWorldPosition("player")
	return playerY
end

-- Advanced marker shapes
function GroundMarker.Renderer:CreateMarkerMesh(markerType, control)
	if markerType == "circle" then
		-- Create a circle using multiple segments
		local segments = 32
		local vertices = {}

		for i = 0, segments do
			local angle = (i / segments) * math.pi * 2
			local x = math.cos(angle)
			local y = math.sin(angle)
			table.insert(vertices, { x = x, y = y })
		end

		return vertices
	elseif markerType == "x" then
		-- Create an X shape
		return {
			{ x = -1, y = -1 },
			{ x = 1, y = 1 },
			{ x = -1, y = 1 },
			{ x = 1, y = -1 },
		}
	elseif markerType == "arrow" then
		-- Create an arrow pointing forward
		return {
			{ x = 0, y = 1 },
			{ x = -0.5, y = -0.5 },
			{ x = 0, y = -0.2 },
			{ x = 0.5, y = -0.5 },
		}
	end
end
