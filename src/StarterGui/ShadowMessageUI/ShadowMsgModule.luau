local CinematicMsgClientModule = {}

--- // SERVICES
local TweenService = game:GetService("TweenService")

--- // OBJECTS
local camera = workspace.CurrentCamera
-- UI Elements
local messageUI = script.Parent
local titleTextLabel: TextLabel = messageUI.TitleText
local textLabelTemplate: TextLabel = messageUI.TextTemplate
local shadowFrame: Frame = messageUI.Shadow

--- // CONFIG
local SHADOW_FRAME_TWEEN_TIME = 0.5
local SHADOW_FRAME_HIDDEN_POSITION = UDim2.fromScale(0, -1)
local SHADOW_FRAME_VISIBLE_POSITION = UDim2.fromScale(0, 0.63)
local TYPEWRITER_EFFECT_SPEED = 0.05 -- Time in seconds between each letter for typewriter effect

--- // VARIABLES
local previousTextLabel: TextLabel = nil -- To keep track of the previous text label for cleanup
type MessageEntry = {
    message: string,
    cframe: CFrame?,
    target: Instance?
}	

local tweenInfo = TweenInfo.new(SHADOW_FRAME_TWEEN_TIME)
local showTitleTween: Tween = TweenService:Create(titleTextLabel, tweenInfo, {TextTransparency = 0})
local hideTitleTween: Tween = TweenService:Create(titleTextLabel, tweenInfo, {TextTransparency = 1})

--- // FUNCTIONS
-------------------------------- // CAMERA FUNCTIONS --------------------------------

local function updateCamera(msgCFrame: CFrame?, msgTarget: Instance?)
    if msgTarget and msgTarget:IsA("Instance") then
        camera.CameraSubject = msgTarget
        camera.CameraType = Enum.CameraType.Attach
    elseif msgCFrame and msgCFrame:IsA("CFrame") then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = msgCFrame
    else
        camera.CameraType = Enum.CameraType.Custom
    end
end

local function moveCameraAlongCurve(vector3Points: { Vector3 })
    -- Currently not implemented
end

local function resetCamera()
    if camera.CameraType ~= Enum.CameraType.Custom then
         camera.CameraType = Enum.CameraType.Custom
    end
end

-------------------------------- // MESSAGE DISPLAY FUNCTIONS --------------------------------

-- Tweens the visibility of the shadow frame by changing its position
local function updateShadowVisibility(isVisible: boolean, isInstant: boolean?)
    if isInstant then
        shadowFrame.Position = isVisible and SHADOW_FRAME_VISIBLE_POSITION or SHADOW_FRAME_HIDDEN_POSITION
        return
    end       
    local goal = {
        Position = isVisible and SHADOW_FRAME_VISIBLE_POSITION or SHADOW_FRAME_HIDDEN_POSITION   
    }
    local tween = TweenService:Create(shadowFrame, tweenInfo, goal)
    tween:Play()
end

-- Displays or hides the title text label based on msgTitle
local function displayTitle(msgTitle: string?)
    titleTextLabel.Text = msgTitle or ""
    if titleTextLabel.Text ~= "" then 
       showTitleTween:Play()
    else
       hideTitleTween:Play()
    end
end

-- Displays the message text with the specified style effect
local function displayText(text: string, style: string)
    if previousTextLabel then
        previousTextLabel:Destroy()
        previousTextLabel = nil
    end

    local textLabel = textLabelTemplate:Clone()
    textLabel.Name = "CinematicTextLabel"
    textLabel.Parent = messageUI
    previousTextLabel = textLabel

    if style == "Typewriter" then
        -- Typewriter effect
        local length = #text
        textLabel.Text = ""
        for i = 1, length do
            if not textLabel.Parent then
                break -- Exit if the textLabel has been destroyed
            end
            textLabel.Text = string.sub(text, 1, i)
            task.wait(TYPEWRITER_EFFECT_SPEED)
        end
    elseif style == "Fade" then
        -- Fade in effect
        textLabel.Text = text
        textLabel.TextTransparency = 1
        local tween = TweenService:Create(textLabel, tweenInfo, {TextTransparency = 0})
        tween:Play()
    else
        -- Instant display 
        textLabel.Text = text
    end
end

-------------------------------- // CINEMATIC MESSAGE MODULE FUNCTIONS --------------------------------

-- Displays a cinematic message with optional title, camera position/target, and style
-- @param msgTitle: If nil, title text label will be hidden in the UI on the client, otherwise displayed above the message text
-- @param msgText: The message text to display
-- @param msgCFrame: If provided, client camera will change to this CFrame in the 3D world
-- @param msgTarget: If provided, client camera will follow this Instance in the 3D world (takes priority over msgCFrame)
-- @param vector3Points: A table of Vector3 points that define the curve path for the camera to follow
-- @param style: 'Typewriter' (letters appear one by one), 'Fade' (text slowly fades in), "Instant" (text instantly appears) - Defaults to instant
function CinematicMsgClientModule.showCinematicMsg(msgTitle: string?, msgText: string, style: string?, msgCFrame: CFrame?, msgTarget: Instance?, vector3Points: {Vector3}?)
    local success, result = pcall(function()
        if not style or style == "" then
            style = "Instant"
        end

        -- Clean up previous text label if it exists to avoid overlap
        if previousTextLabel then
            previousTextLabel:Destroy()
        end

        -- Display title and text
        displayTitle(msgTitle)
        displayText(msgText, style)
        updateShadowVisibility(true, style == "Instant")

        -- Update camera based on provided parameters
        if vector3Points and #vector3Points >= 2 then
            moveCameraAlongCurve(vector3Points)
        elseif msgCFrame or msgTarget then
            updateCamera(msgCFrame, msgTarget)
        end
    end)

    if not success then
        warn("CinematicMsgClientModule | showCinematicMsg: Error displaying cinematic message:", result)
        CinematicMsgClientModule.hideCinematicMessage()
    end
end

function CinematicMsgClientModule.showCinematicMsgSequence(msgTitle: string?, msgTable: { MessageEntry }, style: string?)
	-- Might add this later
end

-- Resets camera, hides shadow frame, and clears text labels
function CinematicMsgClientModule.hideCinematicMessage()
    local success, result = pcall(function()
        updateShadowVisibility(false)
        if previousTextLabel then
            previousTextLabel:Destroy()
            previousTextLabel = nil
        end
        resetCamera()
        titleTextLabel.Text = ""
    end)

    if not success then
        warn("CinematicMsgClientModule | hideCinematicMessage: Error hiding cinematic message:", result)
    end
end

return CinematicMsgClientModule
