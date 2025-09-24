-- This script initializes the game's portraits and integrates them with CinematicMessageService, allowing players to interact with portraits

--- // SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserService = game:GetService("UserService")

--- // OBJECTS
-- Modules
local CinematicMessageService = require(ReplicatedStorage.RSModules.CinematicMessageService)
local CreditsModule = require(ReplicatedStorage.RSModules.CreditsModule)
local DebugService = require(ReplicatedStorage.RSModules.DebugService)

local portraits = script.Parent

--- // VARIABLES
local portraitInfo = {
	-- Texture ID for portrait image    -- Table setup allows for multiple authors
	["rbxassetid://86979555973590"] = {
		{ 5435230355 },
		"",
	}, -- Girl in dress
	["rbxassetid://93624278334526"] = {
		{ 3454078988 },
		"",
	}, -- Goblet
	["rbxassetid://114494434639918"] = {
		{ 90598134 },
		"Professor McGonagall walking through the Hogwarts grounds on a hot summers day.",
	}, -- McG
	["rbxassetid://115683740988825"] = {
		{ 3201271604 },
		"Or yet in wise old Ravenclaw, If you've a ready mind, Where those of wit and learning, Will always find their kind;",
	}, -- Raven
	["rbxassetid://75691649380406"] = {
		{ 507284241 },
		"Portrait of Remus Lupin - It is the quality of one's convictions that determines success, not the number of followers.",
	}, -- Remus
	["rbxassetid://94307842972882"] = {
		{ 1645753175 },
		"Portrait of the late Severus Snape.",
	}, -- Snape
	["rbxassetid://139483694575933"] = {
		{ 272184352, 3183025317 },
		"Two professors sitting on the porch together- Oh they’re saying hello!",
	}, -- Two staff
	-- Rowena
}

local creditsIds = CreditsModule.getCreditsIds() -- A table of user IDs of everyone who contributed to the game
local fullIDsList = {}
local idToName = {}
local db = {}

--- // CONFIG
local DELAY = 2
local PORTRAIT_VIEW_OFFSET_DEFAULT = 10 -- How far in front of the portrait the camera should zoom to. A more robust solution would be to calculate the size of the portrait & adjust the offset based on that, but this is good enough for now
local CD_RANGE = 70 -- ClickDetector max activation distance
local INCLUDE_USERNAME = true -- Should we display username + display name? Ex: Constantin (PhysicallyConstant), EpicDev (AnEpicDev6416)
local CAPTION_INDENT = "    " -- Configurable indent for caption text
local HM_PORTRAIT_IMAGE_MAX_DISTANCE = 100
--- // FUNCTIONS

local function createPortraitCD(framePart)
	local portraitCD = Instance.new("ClickDetector")
	portraitCD.Name = "PortraitClickDetector"
	portraitCD.MaxActivationDistance = CD_RANGE
	portraitCD.Parent = framePart
	return portraitCD
end

local function getFramePart(portraitModel)
	for _, framePart in ipairs(portraitModel:GetDescendants()) do
		if string.find(string.lower(framePart.Name), "frame") then
			return framePart
		end
	end
end

-- Use ROBLOX API to get a formatted player display name string
-- If INCLUDE_USERNAME config is true, will also return the username. Ex: Constantin (PhysicallyConstant)
local function setIdToNameTable(userIDs: { number })
	local success, userInfos = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(userIDs)
	end)

	if success then
		for _, userInfo in ipairs(userInfos) do
			local name
			local userId = userInfo.Id
			if not (userInfo.Username and userInfo.DisplayName) then
				warn(
					"Missing a username or displayname value for",
					userId,
					"Username:",
					userInfo.Username,
					"DisplayName:",
					userInfo.DisplayName
				)
				idToName[userId] = tostring(userId) -- One should hope this never happens
				continue
			end
	
			if INCLUDE_USERNAME then
				if userInfo.Username == userInfo.DisplayName then
					name = userInfo.DisplayName
				else
					name = userInfo.DisplayName .. " (" .. userInfo.Username .. ")"
				end
			else
				name = userInfo.DisplayName
			end
			idToName[userId] = name
		end
	else
		warn("Failed to fetch username info!")
	end
end

local function getNameStr(userId)
	return idToName[userId] or tostring(userId)
end

-- Receives a table of user IDs & returns a formatted string of author display names & usernames
-- @param authorsTable: A list of IDs of portrait authors. Usually just 1 ID
local function formatAuthorsStr(authorsTable)
	if not authorsTable then
		error("Missing authors table param!")
	end
	local authors = ""
	for i, authorId in ipairs(authorsTable) do
		local authorName = getNameStr(authorId)
		if not authorName or authorName == "" then
			warn("Failed to get name string for userID:", authorId)
			authors = ""
			break
		end
		authors ..= authorName .. (i ~= #authorsTable and ", " or "")
	end
	if authors == "" then
		warn("Authors string is empty! Intentional?")
	end
	return authors
end

local function portraitCdClicked(
	player,
	msgTitle: string?,
	msgText: string?,
	style: string?,
	portraitZoomCFrame: CFrame?
)
	-- Basic debounce to prevent server spam
	if db[player.UserId] then
		return
	end
	db[player.UserId] = true
	task.delay(DELAY, function()
		db[player.UserId] = nil
	end)
	if msgText and msgText ~= "" then
		msgText = CAPTION_INDENT .. msgText -- Indent caption text for better readability
	end
	CinematicMessageService.sendCinematicMessage(player, msgTitle, msgText, style, portraitZoomCFrame)
end

local function setupRegularPortrait(portraitModel)
	if not portraitModel:IsA("Model") then
		return
	end -- All portraits are models

	local framePart = getFramePart(portraitModel)
	if not framePart then
		warn("Failed to find a frame part within " .. portraitModel:GetFullName())
		return
	end

	-- Calculate a CFrame in front of the portrait to zoom the camera to
	-- Offset distance is based on the PORTRAIT_VIEW_OFFSET_DEFAULT config variable
	-- A more robust solution would be to calculate the size of the portrait & adjust the offset based on that, but this is good enough for now
	local portraitZoomCFrame =
		CFrame.new(framePart.Position + framePart.CFrame.LookVector * PORTRAIT_VIEW_OFFSET_DEFAULT, framePart.Position)
	DebugService:placeNode(portraitZoomCFrame, nil, nil, 100000)

	local _portraitInfo, authors, caption
	for _, decal in ipairs(portraitModel:GetDescendants()) do
		if not decal:IsA("Decal") then
			continue
		end

		-- Get portrait info from the table above, including the portrait's authors & caption
		_portraitInfo = portraitInfo[decal.Texture]
		if not _portraitInfo then
			continue
		end

		authors = formatAuthorsStr(_portraitInfo[1])
		caption = _portraitInfo[2]

		-- If there's no caption, hide the title on the client (since authors param will be nil) & change caption to the authors. This will look nicer
		if caption == "" then
			caption = "Artwork by " .. authors
			authors = nil
		else
			authors = "Artwork by " .. authors
		end

		if (not authors or authors == "") and (not caption or caption == "") then
			warn(
				"Failed to get author & caption for:",
				portraitModel:GetFullName(),
				tostring(decal.Texture),
				tostring(authors),
				tostring(caption)
			)
			return
		end
	end

	createPortraitCD(framePart).MouseClick:Connect(function(player)
		print("Portrait clicked by", player.Name, "Authors:", authors, "Caption:", caption, _portraitInfo)
		portraitCdClicked(player, authors, caption, "Typewriter", portraitZoomCFrame)
	end)
end

local function getPortraitPart(portraitModel)
	local portraitPart
	for _, d in ipairs(portraitModel:GetDescendants()) do
		if d.Name == "PortraitPart" then
			portraitPart = d
			break
		end
	end
	if portraitPart then
		return portraitPart
	else
		warn("Failed to get portrait part within", portraitModel:GetFullName())
		return nil
	end
end

local function getImageLabel(portraitPart): ImageLabel
	local surfaceGui = Instance.new("SurfaceGui")
	surfaceGui.Name = "HM_Portrait_SurfaceGui"
	surfaceGui.Face = Enum.NormalId.Front
	surfaceGui.MaxDistance = HM_PORTRAIT_IMAGE_MAX_DISTANCE

	local portraitImage = Instance.new("ImageLabel")
	portraitImage.Name = "HM_Portrait_Image"
	portraitImage.Size = UDim2.fromScale(1, 1)
	portraitImage.BackgroundTransparency = 1
	portraitImage.Parent = surfaceGui
	surfaceGui.Parent = portraitPart
	return portraitImage
end

-- Function to set up a headmaster portrait
-- Uses  CreditsModule to get a developer's name & contribution to the game
local function setupHeadmasterPortrait(portraitModel, framePart)
	local creditsId = portraitModel:GetAttribute("CreditsId") -- Assign CreditsId number attribute to a portrait for a deveoper to be shown on it
	if not creditsId or creditsId == 0 then
		-- warn("Missing credits ID for a headmaster portrait!")
		return
	end

	local portraitPart = getPortraitPart(portraitModel)
	print("Setting up headmaster portrait for:", getNameStr(creditsId), creditsId)

	local PLACEHOLDER_IMAGE = "rbxassetid://0" -- replace with placeholder image

	-- fetch the thumbnail
	local userId = creditsId
	local thumbType = Enum.ThumbnailType.HeadShot
	local thumbSize = Enum.ThumbnailSize.Size420x420

	local success, result = pcall(function()
		local content, isReady = Players:GetUserThumbnailAsync(userId, thumbType, thumbSize)
		-- set the ImageLabel's content to the user thumbnail
		local imageLabel = getImageLabel(portraitPart)
		imageLabel.Image = (isReady and content) or PLACEHOLDER_IMAGE
	end)

	if not success then
		warn("Error:", result)
	end
	-- Calculate a CFrame in front of the portrait to zoom the camera to
	-- Offset distance is based on the PORTRAIT_VIEW_OFFSET_DEFAULT config variable
	-- A more robust solution would be to calculate the size of the portrait & adjust the offset based on that, but this is good enough for now
	local portraitZoomCFrame =
		CFrame.new(framePart.Position + framePart.CFrame.LookVector * PORTRAIT_VIEW_OFFSET_DEFAULT, framePart.Position)
	DebugService:placeNode(portraitZoomCFrame, nil, nil, 100000)

	local contributorName = getNameStr(creditsId)
	local contribution = CreditsModule.getContribution(creditsId)
	createPortraitCD(framePart).MouseClick:Connect(function(player)
		portraitCdClicked(player, contributorName, contribution, "Fade", portraitZoomCFrame)
	end)

	createPortraitCD(portraitPart).MouseClick:Connect(function(player)
		portraitCdClicked(player, contributorName, contribution, "Fade", portraitZoomCFrame)
	end)
end

--- // MAIN
-- Initialize full ID list to not overload ROBLOX services with multiple requests
for _, creditsId in ipairs(creditsIds) do
	table.insert(fullIDsList, creditsId)
end

for _, _portraitInfo in pairs(portraitInfo) do
	local authorsTable = _portraitInfo[1]
	for _, artistId in ipairs(authorsTable) do
		table.insert(fullIDsList, artistId)
	end
end

print("Full ID list:", fullIDsList)
setIdToNameTable(fullIDsList)
print("ID to name list:", idToName)

for _, portraitModel in ipairs(portraits:GetChildren()) do
	setupRegularPortrait(portraitModel)
end

for _, portraitModel in ipairs(portraits.AI_Portraits:GetChildren()) do
	setupRegularPortrait(portraitModel)
end

for _, portraitModel in ipairs(portraits.HeadmasterPortraits:GetChildren()) do
	if not portraitModel:IsA("Model") then
		continue
	end -- All portraits are models

	local framePart = getFramePart(portraitModel)
	if not framePart then
		warn("Failed to find a frame part within " .. portraitModel:GetFullName())
		continue
	end

	setupHeadmasterPortrait(portraitModel, framePart)
end
