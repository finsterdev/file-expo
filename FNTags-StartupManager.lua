local DataStoreService = game:GetService("DataStoreService")
local playerDataStore = DataStoreService:GetDataStore("FTagsPlayerData")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeamsData = require(ReplicatedStorage.FTagsDataBroker.DataSheet)
local RoleSlotsControl = ReplicatedStorage.FTagsDataBroker.RSControl

local defaultTeam = "General"
local defaultSubrole = "Pedestrian"
local defaultCharName = "New Player"
local defaultCharDesc = "Bio..."

local function loadPlayerData(player)
	local userId = player.UserId
	local success, data = pcall(function()
		return playerDataStore:GetAsync(tostring(userId))
	end)

	if success and data then
		local savedTeam = data.CurrentTeam
		local savedSubrole = data.CurrentSubrole

		if TeamsData[savedTeam] and TeamsData[savedTeam].Subroles then
			local subroleFound = false
			for subroleKey, subroleInfo in pairs(TeamsData[savedTeam].Subroles) do
				if subroleInfo.Name == savedSubrole then
					subroleFound = true
					local maxSpaces = subroleInfo.Spaces
					local currentPopulation = RoleSlotsControl:GetAttribute(savedTeam..savedSubrole.."Population") or 0

					if maxSpaces == 0 or currentPopulation < maxSpaces then
						player:SetAttribute("CurrentTeam", savedTeam)
						player:SetAttribute("CurrentSubrole", savedSubrole)
						player:SetAttribute("CharName", data.CharName or defaultCharName)
						player:SetAttribute("CharDesc", data.CharDesc or defaultCharDesc)
						print(player.Name .. " data loaded. Team: " .. player:GetAttribute("CurrentTeam") .. ", Subrole: " .. player:GetAttribute("CurrentSubrole") .. ", Name: " ..player:GetAttribute("CharName").. ", Description: " ..player:GetAttribute("CharDesc"))
						return
					else
						print(player.Name .. "'s saved role (" .. savedTeam .. ":" .. savedSubrole .. ") is full. Applying default role.")
						break
					end
				end
			end

			if not subroleFound then
				print(player.Name .. "'s saved subrole (" .. savedTeam .. ":" .. savedSubrole .. ") is invalid. Applying default role.")
			end
		else
			print(player.Name .. "'s saved team (" .. savedTeam .. ") is invalid. Applying default role.")
		end
	else
		if not success then
			warn("Error loading data for " .. player.Name .. ": " .. data)
		end
		print(player.Name .. " has joined for the first time or load failed. Default data applied.")
	end

	player:SetAttribute("CurrentTeam", defaultTeam)
	player:SetAttribute("CurrentSubrole", defaultSubrole)
	player:SetAttribute("CharName", defaultCharName)
	player:SetAttribute("CharDesc", defaultCharDesc)
end

local function saveData(player)
	local userId = player.UserId
	local dataToSave = {
		CurrentTeam = player:GetAttribute("CurrentTeam"),
		CurrentSubrole = player:GetAttribute("CurrentSubrole"),
		CharName = player:GetAttribute("CharName"),
		CharDesc = player:GetAttribute("CharDesc")
	}

	local success, errorMessage = pcall(function()
		playerDataStore:SetAsync(tostring(userId), dataToSave)
	end)

	if success then
		print(player.Name .. "'s data saved.")
	else
		warn("Error saving data for " .. player.Name .. ": " .. errorMessage)
	end
end

game.Players.PlayerAdded:Connect(loadPlayerData)

game.Players.PlayerRemoving:Connect(saveData)
