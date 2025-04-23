-- Localscript (inside GUI)
local replicatedstorage = game:GetService("ReplicatedStorage")
local MarketService = game:GetService("MarketplaceService")
local TextService = game:GetService("TextService")
local broker = replicatedstorage.FTagsDataBroker:WaitForChild("UpdateInfo")
local TeamsData = require(replicatedstorage.FTagsDataBroker:WaitForChild("DataSheet"))
local CommonsUpd = replicatedstorage.FTagsDataBroker.UpdCommons
local RoleSlotsControl = replicatedstorage.FTagsDataBroker.RSControl
local button = script.Parent.ControlPanel.PlrDetails
local StaffPlrsModule = require(replicatedstorage.FTagsDataBroker:WaitForChild("DSP"))
local StaffPlrs = StaffPlrsModule.Data

local frame = script.Parent.Main
local mainrolesTMP = frame.Roles.RolesList.ExampleButton
local subrolesTMP = frame.Roles.SubrolesList.ExampleButton

local PMainRoleKey = "" -- Changed to store the space-friendly key
local PSubRole = ""
local CharNameInput = frame.TypeDetails.CharNameInput
local CharDescInput = frame.TypeDetails.CharDescInput
local CharName = ""
local CharDesc = ""

local TweensService = game:GetService("TweenService")
local standardtweeninfo = TweenInfo.new(1, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, 0, false, 0)

local subroleButtons = {} -- To store references to the created subrole buttons

local function sanitizeAttributeName(name)
	return string.gsub(name, " ", "_")
end

function ClearSubroles()
	for i, v in frame.Roles.SubrolesList:GetChildren() do
		if v:IsA("TextButton") and v.Name ~= "ExampleButton" then
			v.Visible = false
			v:Destroy()
		end
	end
	subroleButtons = {} -- Clear the button references when subroles are cleared
end

function SendInfo()
	broker:FireServer(PMainRoleKey, PSubRole, CharDesc, CharName) -- Send the space-friendly key
end

function updateSubroleButtonText(subroleName, currentPop, maxPop)
	for _, button in ipairs(subroleButtons) do
		if button.Name == subroleName then
			if maxPop == 0 then
				button.Text = subroleName
			else
				button.Text = subroleName.." (" ..tostring(currentPop).."/"..tostring(maxPop)..")"
			end
			break
		end
	end
end

function fillSubRoles()
	ClearSubroles()
	local currentTeamData = TeamsData[PMainRoleKey]
	if currentTeamData and currentTeamData.Subroles then
		for _, subroleData in pairs(currentTeamData.Subroles) do -- Iterate through subroles of the selected team
			local TemClone = subrolesTMP:Clone()
			TemClone.Name = subroleData.Name
			local sanitizedTeamKey = sanitizeAttributeName(PMainRoleKey)
			local sanitizedSubRoleName = sanitizeAttributeName(subroleData.Name)
			local attributeName = sanitizedTeamKey .. sanitizedSubRoleName .. "Population"
			local CurrentRolePop = RoleSlotsControl:GetAttribute(attributeName) or 0
			local MaxrolePop = subroleData.Spaces

			if MaxrolePop == 0 then
				TemClone.Text = subroleData.Name
			else
				TemClone.Text = subroleData.Name.." (" ..tostring(CurrentRolePop).."/"..tostring(MaxrolePop)..")"
			end
			TemClone.Parent = frame.Roles.SubrolesList
			TemClone.Visible = true
			if subroleData.Staff == false then
				TemClone.StaffGradient.Enabled = false
			else
				TemClone.StaffGradient.Enabled = true
			end
			if subroleData.Pass == 0 then
				TemClone.PremiumGradient.Enabled = false
			else
				TemClone.PremiumGradient.Enabled = true
			end

			-- Store the button reference
			table.insert(subroleButtons, TemClone)

			TemClone.MouseButton1Click:Connect(function()
				if MaxrolePop == 0 or CurrentRolePop < MaxrolePop then
					if subroleData.Pass == 0 and subroleData.Staff == false then
						PSubRole = subroleData.Name
						SendInfo()
					elseif subroleData.Staff ~= false then
						local isStaff = false
						for _, ids in subroleData.Staff do
							if game.Players.LocalPlayer.UserId == ids then
								PSubRole = subroleData.Name
								SendInfo()
								isStaff = true
								break
							end
						end
						if not isStaff then
							print("You are not part of the staff.")
						end
					elseif subroleData.Pass ~= 0 then
						local ownsPass = MarketService:UserOwnsGamePassAsync(game.Players.LocalPlayer.UserId, subroleData.Pass)
						if ownsPass == true then
							PSubRole = subroleData.Name
							SendInfo()
						else
							MarketService:PromptGamePassPurchase(game.Players.LocalPlayer, subroleData.Pass)
						end
					end
				else
					TemClone.Text = "Role is full!"
					wait(1)
					TemClone.Text = subroleData.Name.." (" ..CurrentRolePop.."/"..MaxrolePop..")"
				end
			end)
		end
	end
end

function fillMainRoles()
	for teamKey, teamData in pairs(TeamsData) do -- Iterate through the space-friendly keys
		local TempClone = mainrolesTMP:Clone()
		TempClone.Name = teamData.Name -- Use the actual team name for the button's Name (for potential later use)
		TempClone.Text = teamData.Name -- Display the actual team name
		TempClone.Parent = frame.Roles.RolesList
		TempClone.Visible = true
		TempClone.MouseButton1Click:Connect(function()
			PMainRoleKey = teamKey -- Store the space-friendly key
			frame.Roles.RolesList.Visible = false
			frame.Roles.SubrolesList.Visible = true
			frame.Roles.Back.Visible = true
			fillSubRoles()
		end)
	end
end

fillMainRoles()

CharNameInput.FocusLost:Connect(function(enterPressed)
	CharName = tostring(CharNameInput.Text)
	SendInfo()
end)

CharDescInput.FocusLost:Connect(function(enterPressed)
	CharDesc = tostring(CharDescInput.Text)
	SendInfo()
end)

-- Listen for changes to the RoleSlotsControl attributes
RoleSlotsControl.AttributeChanged:Connect(function(attributeName)
	for teamKey, teamData in pairs(TeamsData) do
		local sanitizedTeamKey = sanitizeAttributeName(teamKey)
		if teamData and teamData.Subroles then
			for _, subroleData in pairs(teamData.Subroles) do
				local sanitizedSubRoleName = sanitizeAttributeName(subroleData.Name)
				local expectedAttributeName = sanitizedTeamKey .. sanitizedSubRoleName .. "Population"
				if attributeName == expectedAttributeName then
					local currentPop = RoleSlotsControl:GetAttribute(attributeName) or 0
					local maxPop = subroleData.Spaces
					updateSubroleButtonText(subroleData.Name, currentPop, maxPop) -- Use the actual name for updating button text
					break -- Once the relevant button is updated, we can exit the inner loop
				end
			end
		end
	end
end)

-- UI Hiding Logic (no changes needed here)
local multiplayerFrame = script.Parent:WaitForChild("Multiplayer")
local staffPanel = script.Parent:WaitForChild("Staff")

local function HideAllUI()
	local ready = false
	local shouldWait = false

	if frame.Visible then
		local frameTween = TweensService:Create(frame, standardtweeninfo, {Size = UDim2.fromScale(0.317, 0)})
		frameTween:Play()
		shouldWait = true
	end

	if multiplayerFrame.Visible then
		local multiplayerTween = TweensService:Create(multiplayerFrame, standardtweeninfo, {Size = UDim2.fromScale(0.317, 0)})
		multiplayerTween:Play()
		shouldWait = true
	end

	if staffPanel.Visible then
		TweensService:Create(staffPanel, standardtweeninfo, {Size = UDim2.fromScale(0, 0.935)}):Play()
		shouldWait = true
	end

	if shouldWait then
		task.wait(standardtweeninfo.Time) -- Only wait if a tween was played
	end

	frame.Visible = false
	multiplayerFrame.Visible = false
	staffPanel.Visible = false
	ready = true
	return ready
end

local ControlPanel = script.Parent:WaitForChild("ControlPanel")

ControlPanel.Multiplayer.MouseButton1Click:Connect(function()
	if multiplayerFrame.Visible == false then
		HideAllUI()
		multiplayerFrame.Visible = true
		TweensService:Create(multiplayerFrame, standardtweeninfo, {Size = UDim2.fromScale(0.317, 0.38)}):Play()
	else
		TweensService:Create(multiplayerFrame, standardtweeninfo, {Size = UDim2.fromScale(0.317, 0)}):Play()
		task.wait(standardtweeninfo.Time)
		multiplayerFrame.Visible = false
	end
end)

ControlPanel.PlrDetails.MouseButton1Click:Connect(function()
	if frame.Visible == false then
		HideAllUI()
		frame.Visible = true
		TweensService:Create(frame, standardtweeninfo, {Size = UDim2.fromScale(0.317, 0.38)}):Play()
	else
		TweensService:Create(frame, standardtweeninfo, {Size = UDim2.fromScale(0.317, 0)}):Play()
		task.wait(standardtweeninfo.Time)
		frame.Visible = false
	end
end)

local plrIsStaff = false
ControlPanel.SCP.MouseButton1Click:Connect(function()
	local player = game.Players.LocalPlayer
	for _, userid in ipairs(StaffPlrs) do
		if player.UserId == userid then
			plrIsStaff = true
		end
	end
	if staffPanel.Visible == false and plrIsStaff == true then
		HideAllUI()
		staffPanel.Visible = true
		TweensService:Create(staffPanel, standardtweeninfo, {Size = UDim2.fromScale(0.132, 0.935)}):Play()
	elseif plrIsStaff == false then
		staffPanel:Destroy()
		ControlPanel.SCP:Destroy()
	else
		TweensService:Create(staffPanel, standardtweeninfo, {Size = UDim2.fromScale(0, 0.935)}):Play()
		task.wait(standardtweeninfo.Time)
		staffPanel.Visible = false
	end
end)

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.B then
		HideAllUI()
	end
end)

local hideNotice = script.Parent.TextLabel

function noticeDet()
	if frame.Visible or multiplayerFrame.Visible or staffPanel.Visible then
		hideNotice.Visible = true
	else
		hideNotice.Visible = false
	end
end

while true do noticeDet() task.wait() end
