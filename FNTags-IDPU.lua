local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextService = game:GetService("TextService")
local TeamsData = require(ReplicatedStorage.FTagsDataBroker:WaitForChild("DataSheet"))
local NametagTemplate = script.Parent.Nametag
local StaffPlayersModule = require(ReplicatedStorage.FTagsDataBroker:WaitForChild("DSP"))
local StaffPlayers = StaffPlayersModule.Data

local function updateNametag(player)
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	local head = character:WaitForChild("Head")
	local nametag = head:FindFirstChild("Nametag")

	if not nametag then
		nametag = NametagTemplate:Clone()
		nametag.Parent = head
	end

	local frame = nametag:FindFirstChild("Frame")
	if frame then
		local staffIcon = frame:FindFirstChild("Stafficon")
		local staffGradient = frame:FindFirstChild("UIStroke"):FindFirstChild("Staff")
		local PremiumGradient = frame:FindFirstChild("UIStroke"):FindFirstChild("Premium")
		local charNameLabel = frame:FindFirstChild("charname")
		local roleLabel = frame:FindFirstChild("role")
		local usernameLabel = frame:FindFirstChild("username")

		if staffIcon and charNameLabel and roleLabel and usernameLabel then
			usernameLabel.Text = player.DisplayName.." (@"..player.Name..")"

			local currentTeamKey = player:GetAttribute("CurrentTeam")
			local currentSubroleName = player:GetAttribute("CurrentSubrole")
			local currentCharName = player:GetAttribute("CharName")

			if currentTeamKey and TeamsData[currentTeamKey] and TeamsData[currentTeamKey].Subroles then
				local teamData = TeamsData[currentTeamKey]
				local subroleData = nil

				for subroleKey, data in pairs(teamData.Subroles) do
					if data.Name == currentSubroleName then
						subroleData = data
						break
					end
				end

				if subroleData then
					roleLabel.Text = teamData.Name.. ", " ..subroleData.Name
					roleLabel.TextColor3 = teamData.Color

					local filterName = TextService:FilterStringAsync(currentCharName, player.UserId, Enum.TextFilterContext.PrivateChat)
					charNameLabel.Text = filterName:GetNonChatStringForBroadcastAsync()

					local isStaff = false
					if typeof(subroleData.Staff) == "table" then
						for _, userId in ipairs(subroleData.Staff) do
							if userId == player.UserId then
								isStaff = true
								frame:FindFirstChild("UIStroke").Enabled = true
								break
							end
						end
					end
					for _, userid in ipairs(StaffPlayers) do
						if player.UserId == userid then
							isStaff = true
							frame:FindFirstChild("UIStroke").Enabled = true
						end
					end

					staffIcon.Visible = isStaff
					staffGradient.Enabled = isStaff
					if isStaff == true then
						staffIcon.ImageColor3 = teamData.Color
					end

					if player.MembershipType == Enum.MembershipType.Premium then
						PremiumGradient.Enabled = true
						frame:FindFirstChild("UIStroke").Enabled = true
					end

				else
					roleLabel.Text = ""
					staffIcon.Visible = false
				end
			else
				roleLabel.Text = ""
				staffIcon.Visible = false
			end
		end
	end
end

game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		task.wait(0.1)
		updateNametag(player)
	end)
	player:GetAttributeChangedSignal("CurrentTeam"):Connect(function()
		updateNametag(player)
	end)
	player:GetAttributeChangedSignal("CurrentSubrole"):Connect(function()
		updateNametag(player)
	end)
	player:GetAttributeChangedSignal("CharName"):Connect(function()
		updateNametag(player)
	end)
	player:GetAttributeChangedSignal("CharDesc"):Connect(function()
		updateNametag(player)
	end)
end)

for _, player in ipairs(game.Players:GetPlayers()) do
	if player.Character then
		task.wait(0.1)
		updateNametag(player)
	end
end
