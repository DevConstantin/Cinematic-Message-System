
--- // SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--- // OBJECTS
-- Modules
local ShadowMsgModule = require(script.Parent.ShadowMsgModule)

local msgExitButton = script.Parent.ExitButton

-- Remote Events
local shadowMsgEvents = ReplicatedStorage.RemoteEvents.shadowMsgEvents
local msgEvent = shadowMsgEvents.ShadowMsg
local msgSequenceEvent = shadowMsgEvents.ShadowMsgSequence

--- // MAIN
msgExitButton.MouseButton1Click:Connect(ShadowMsgModule.hideCinematicMessage)
msgEvent.OnClientEvent:Connect(ShadowMsgModule.showShadowMsg)
msgSequenceEvent.OnClientEvent:Connect(ShadowMsgModule.showShadowMsgSequence)