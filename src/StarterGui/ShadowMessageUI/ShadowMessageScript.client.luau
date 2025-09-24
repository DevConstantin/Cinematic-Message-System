-- This script initializes the cinematic message UI, and initializes events to receive message requests from the server

--- // SERVICES
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--- // OBJECTS
-- Modules
local CinematicMsgClientModule = require(script.Parent.ShadowMsgModule)
-- Player
local localPlayer = Players.LocalPlayer
local mouse = localPlayer:GetMouse()

-- UI Elements
local messageUI = script.Parent
local mainFrame = messageUI.MainFrame
local titleTextLabel: TextLabel = mainFrame.TitleText
local textLabelTemplate: TextLabel = mainFrame.TextTemplate
local titleLine: ImageLabel = mainFrame.LineUnderTitle
local msgExitButton: TextButton = mainFrame.ExitButton
local shadowFrame: Frame = messageUI.Shadow

-- Remote Events
local shadowMsgEvents = ReplicatedStorage.RemoteEvents.ShadowMsgEvents
local msgEvent = shadowMsgEvents.ShadowMsg
local msgSequenceEvent = shadowMsgEvents.ShadowMsgSequence

--- // MAIN
-- Initial UI setup - hide elements until needed, ensuring smooth appearance when first used
textLabelTemplate.Text = "" -- Hide the template label
titleTextLabel.Text = ""
titleLine.BackgroundTransparency = 1
titleLine.UIStroke.Enabled = false
titleLine.ImageLabel.ImageTransparency = 1
titleLine.ImageLabel2.ImageTransparency = 1
shadowFrame.Position = UDim2.fromScale(0, 1) -- Start hidden
msgExitButton.Visible = false
messageUI.Enabled = true -- Ensure the UI is enabled now that setup is done

-- Connect mouse and button events to module functions
mouse.Button1Down:Connect(CinematicMsgClientModule.onMouseClick)
msgExitButton.MouseButton1Click:Connect(CinematicMsgClientModule.hideCinematicMessage)

-- Connect RemoteEvents to module functions
msgEvent.OnClientEvent:Connect(CinematicMsgClientModule.showCinematicMessage)
msgSequenceEvent.OnClientEvent:Connect(CinematicMsgClientModule.showCinematicMessageSequence)