-- Client request manager (in ScriptService)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local dataTransferEvent = ReplicatedStorage.FTagsDataBroker:WaitForChild("UpdateInfo")
local teamsdata_module = require(ReplicatedStorage.FTagsDataBroker:WaitForChild("DataSheet"))
local ToolsStorage = game:GetService("ServerStorage"):WaitForChild("Tools")
local UpdateCommons = ReplicatedStorage.FTagsDataBroker:WaitForChild("UpdCommons")
local RoleSlotsControl = ReplicatedStorage.FTagsDataBroker.RSControl

local function sanitizeAttributeName(name)
	return string.gsub(name, " ", "_")
end

local function updateRolePopulation()
	for mainRoleName, mainRoleData in pairs(teamsdata_module) do
		if mainRoleData and mainRoleData.Subroles then
			for _, subRoleData in pairs(mainRoleData.Subroles) do
				local subRoleDisplayName = subRoleData.Name
				local sanitizedSubRoleName = sanitizeAttributeName(subRoleDisplayName)
				local populationCount = 0

				for _, plr in game:GetService("Players"):GetChildren() do
					local playerTeam = plr:GetAttribute("CurrentTeam")
					local playerSubrole = plr:GetAttribute("CurrentSubrole")
					if playerTeam == mainRoleName and playerSubrole == subRoleDisplayName then
						populationCount += 1
					end
				end

				local attributeName = sanitizeAttributeName(mainRoleName) .. sanitizedSubRoleName .. "Population"
				RoleSlotsControl:SetAttribute(attributeName, populationCount)
			end
		end
	end
end

dataTransferEvent.OnServerEvent:Connect(function(player, mainrole, subrole, chardesc, charname)
	player:SetAttribute("CurrentTeam", mainrole)
	player:SetAttribute("CurrentSubrole", subrole)
	player:SetAttribute("CharName", charname)
	player:SetAttribute("CharDesc", chardesc)

	local pbackpack = player:FindFirstChild("Backpack")
	if pbackpack then
		for _, v in ipairs(pbackpack:GetChildren()) do
			if v:IsA("Tool") then
				v:Destroy()
			end
		end

		local mainRoleData = teamsdata_module[mainrole]

		if mainRoleData and mainRoleData.Subroles then
			for _, subRoleData in pairs(mainRoleData.Subroles) do
				if subRoleData.Name == subrole then
					if subRoleData.Tools ~= false then
						if typeof(subRoleData.Tools) == "table" then
							for _, toolName in ipairs(subRoleData.Tools) do
								local toolTemplate = ToolsStorage:FindFirstChild(toolName)
								if toolTemplate and toolTemplate:IsA("Tool") then
									local tclone = toolTemplate:Clone()
									tclone.Parent = pbackpack
								end
							end
						end
					end
					break
				end
			end
		end
	end

	updateRolePopulation()
end)

game.Players.PlayerAdded:Connect(updateRolePopulation)
game.Players.PlayerRemoving:Connect(updateRolePopulation)

updateRolePopulation()
UpdateCommons.OnServerEvent:Connect(updateRolePopulation)
