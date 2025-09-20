local CinematicMsgClientModule = {}

--- // SERVICES
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

--- // OBJECTS
local camera = workspace.CurrentCamera
-- UI Elements
local messageUI = script.Parent
local mainFrame = messageUI.MainFrame
local titleTextLabel: TextLabel = mainFrame.TitleText
local lineUnderTitle: ImageLabel = mainFrame.LineUnderTitle
local textLabelTemplate: TextLabel = mainFrame.TextTemplate
local msgExitButton = mainFrame.ExitButton
local shadowFrame: Frame = messageUI.Shadow

--local typeWriterSound = SoundService.UI.TypewriterDialogueSound

--- // CONFIG
local SHADOW_FRAME_TWEEN_TIME = 1
local TEXT_TWEEN_TIME = 2
local SHADOW_FRAME_HIDDEN_POSITION = UDim2.fromScale(0, 1)
local SHADOW_FRAME_VISIBLE_POSITION = UDim2.fromScale(0, 0.63)
local TYPEWRITER_EFFECT_SPEED = 0.02 -- Time in seconds between each letter for typewriter effect

--- // VARIABLES
local previousTextLabel: TextLabel = nil -- To keep track of the previous text label for cleanup
local currentCameraTween: Tween = nil -- To keep track of the current camera tween for cleanup
type MessageEntry = {
    message: string,
    cframe: CFrame?,
    target: Instance?
}	

local showTextTweenInfo = TweenInfo.new(TEXT_TWEEN_TIME)
local hideTextTweenInfo = TweenInfo.new(TEXT_TWEEN_TIME / 4) -- Hide faster than show
local showTitleTween: Tween = TweenService:Create(titleTextLabel, showTextTweenInfo, {TextTransparency = 0})
local hideTitleTween: Tween = TweenService:Create(titleTextLabel, hideTextTweenInfo, {TextTransparency = 1})
--- // FUNCTIONS
-------------------------------- // CAMERA FUNCTIONS --------------------------------

local function updateCamera(msgCFrame: CFrame?, msgTarget: Instance?)
    if currentCameraTween then
        currentCameraTween:Cancel()
        currentCameraTween = nil
    end

    if msgTarget and msgTarget:IsA("Instance") then
        camera.CameraSubject = msgTarget
        camera.CameraType = Enum.CameraType.Attach
    elseif msgCFrame and typeof(msgCFrame) == "CFrame" then
        local currentCameraCFrame = camera.CFrame
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = currentCameraCFrame -- Prevents sudden jump to new CFrame
        local camTweenLength = math.clamp((currentCameraCFrame.Position - msgCFrame.Position).Magnitude / 50, 0.5, 3) -- Duration based on distance, clamped between 0.5 and 3 seconds to avoid too fast/slow tweens
        currentCameraTween = TweenService:Create(camera, TweenInfo.new(camTweenLength, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {CFrame = msgCFrame})
        currentCameraTween:Play()
    elseif camera.CameraType ~= Enum.CameraType.Custom then
        -- Reset to default camera behavior if no valid CFrame or target is provided
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
    local tween = TweenService:Create(shadowFrame, TweenInfo.new(SHADOW_FRAME_TWEEN_TIME), goal)
    tween:Play()
end

-- Displays or hides the title text label based on msgTitle
-- Input can be nil or empty string to hide the title & line under it
local function updateTitle(msgTitle: string?, isInstant: boolean?)
    if not msgTitle then
        msgTitle = ""
    end

    titleTextLabel.Text = msgTitle
    if isInstant then
        titleTextLabel.TextTransparency = msgTitle ~= "" and 0 or 1
        lineUnderTitle.BackgroundTransparency = msgTitle ~= "" and 0 or 1
        lineUnderTitle.ImageLabel.ImageTransparency = msgTitle ~= "" and 0 or 1
        lineUnderTitle.ImageLabel2.ImageTransparency = msgTitle ~= "" and 0 or 1
        lineUnderTitle.UIStroke.Enabled = msgTitle ~= ""
        return
    end

    if titleTextLabel.Text ~= "" then
       showTitleTween:Play()
    else
       hideTitleTween:Play()
    end

    -- Also tween the line under the title to match visibility
    local titleLineGoal = {BackgroundTransparency = titleTextLabel.Text ~= "" and 0 or 1}
    local imageGoal = {ImageTransparency = titleTextLabel.Text ~= "" and 0 or 1}
    local tweenInfo = titleTextLabel.Text ~= "" and showTextTweenInfo or hideTextTweenInfo
    TweenService:Create(lineUnderTitle, tweenInfo, titleLineGoal):Play()
    TweenService:Create(lineUnderTitle.ImageLabel, tweenInfo, imageGoal):Play()
    TweenService:Create(lineUnderTitle.ImageLabel2, tweenInfo, imageGoal):Play()
end

-- Displays the message text with the specified style effect
local function displayText(text: string, style: string)
    msgExitButton.Visible = true

    if previousTextLabel then
        previousTextLabel:Destroy()
        previousTextLabel = nil
    end

    -- Text can be nil or empty, in which case we just skip displaying it
    if text == "" or text == nil then
        return
    end

    -- Create and configure new text label
    local textLabel = textLabelTemplate:Clone()
    textLabel.Name = "CinematicTextLabel"
    textLabel.Parent = messageUI
    previousTextLabel = textLabel

    if style == "Typewriter" then
        -- Typewriter effect
        local length = #text
        textLabel.Text = ""
        task.spawn(function()
            task.wait(0.1) -- Small initial delay before starting typewriter effect
            for i = 1, length do
                if not textLabel.Parent then
                    break -- Exit if the textLabel has been destroyed
                end
                textLabel.Text = string.sub(text, 1, i)
                task.wait(TYPEWRITER_EFFECT_SPEED)
            end
        end)
    elseif style == "Fade" then
        -- Fade in effect
        textLabel.Text = text
        textLabel.TextTransparency = 1
        local tween = TweenService:Create(textLabel, showTextTweenInfo, {TextTransparency = 0})
        tween:Play()
    else
        -- Instant display
        textLabel.Text = text
    end
end

-------------------------------- // CINEMATIC MESSAGE MODULE FUNCTIONS --------------------------------

-- Validates if at least one of msgText, msgCFrame, msgTarget, or vector3Points is provided
local function shouldDisplayCinematicMessage(msgText: string?, msgCFrame: CFrame?, msgTarget: Instance?, vector3Points: { Vector3 }?)
    if (msgText == "" or msgText == nil) and msgCFrame == nil and msgTarget == nil and (not vector3Points or #vector3Points < 2) then
        warn("CinematicMsgClientModule | showCinematicMsg: Missing msgText, msgCFrame, msgTarget, and vector3Points params! You must provide at least one. Returning.")
        return false
    end
           -- Prevent displaying the same message again if it's already shown
    if messageUI:GetAttribute("CurrentMessage") == msgText then
        print("CinematicMsgClientModule | showCinematicMsg: Same message already displayed, ignoring.")
        return false
    end

    return true
end

-- Displays a cinematic message with optional title, camera position/target, and style
-- @param msgTitle: If nil, title text label will be hidden in the UI on the client, otherwise displayed above the message text
-- @param msgText: The message text to display
-- @param msgCFrame: If provided, client camera will change to this CFrame in the 3D world
-- @param msgTarget: If provided, client camera will follow this Instance in the 3D world (takes priority over msgCFrame)
-- @param vector3Points: A table of Vector3 points that define the curve path for the camera to follow
-- @param style: 'Typewriter' (letters appear one by one), 'Fade' (text slowly fades in), "Instant" (text instantly appears) - Defaults to instant
function CinematicMsgClientModule.showCinematicMessage(msgTitle: string?, msgText: string?, style: string?, msgCFrame: CFrame?, msgTarget: Instance?, vector3Points: {Vector3}?)
    local success, result = pcall(function()
        if not shouldDisplayCinematicMessage(msgText, msgCFrame, msgTarget, vector3Points) then return end

        messageUI:SetAttribute("CurrentMessage", msgText)

        if not style or style == "" then
            style = "Instant"
        end
        -- Clean up previous text label if it exists to avoid overlap
        if previousTextLabel then
            previousTextLabel:Destroy()
        end

        -- Display title and text
        updateTitle(msgTitle, style == "Instant")
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

function CinematicMsgClientModule.showCinematicMessageSequence(msgTitle: string?, msgTable: { MessageEntry }, style: string?)
	-- Might add this later
end

-- Resets camera, hides shadow frame, and clears text labels
function CinematicMsgClientModule.hideCinematicMessage()
    local success, result = pcall(function()
        messageUI:SetAttribute("CurrentMessage", nil)
        updateShadowVisibility(false)
        updateTitle(nil)
        if previousTextLabel then
            previousTextLabel:Destroy()
            previousTextLabel = nil
        end
        msgExitButton.Visible = false
        resetCamera()
    end)

    if not success then
        warn("CinematicMsgClientModule | hideCinematicMessage: Error hiding cinematic message:", result)
    end
end

-- Hide the line's UIStroke when the hide title tween starts playing
showTitleTween:GetPropertyChangedSignal("PlaybackState"):Connect(function()
    print("Show title tween playback state changed to:", hideTitleTween.PlaybackState)
    if showTitleTween.PlaybackState == Enum.PlaybackState.Completed then
        lineUnderTitle.UIStroke.Enabled = true
    elseif showTitleTween.PlaybackState == Enum.PlaybackState.Cancelled then
        lineUnderTitle.UIStroke.Enabled = false
    end
end)

-- Hide the line's UIStroke when the hide title tween starts playing
hideTitleTween:GetPropertyChangedSignal("PlaybackState"):Connect(function()
    print("Hide title tween playback state changed to:", hideTitleTween.PlaybackState)
    if hideTitleTween.PlaybackState == Enum.PlaybackState.Playing then
        lineUnderTitle.UIStroke.Enabled = false
    end
end)

return CinematicMsgClientModule
