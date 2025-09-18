
--- // SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Modules
local ShadowMsgModule = require(script.Parent.ShadowMsgModule)

-- Remote Events
local shadowMsgEvents  = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ShadowMsgEvents")
local msgEvent         = shadowMsgEvents:WaitForChild("ShadowMsg")
local msgSequenceEvent = shadowMsgEvents:WaitForChild("ShadowMsgSequence")

--- // MAIN
msgEvent.OnClientEvent:Connect(ShadowMsgModule.showShadowMsg)
msgSequenceEvent.OnClientEvent:Connect(ShadowMsgModule.showShadowMsgSequence)