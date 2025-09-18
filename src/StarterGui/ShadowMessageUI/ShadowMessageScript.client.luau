
--- // SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Modules
local ShadowMsgModule = require(script.Parent.ShadowMsgModule)

-- Remote Events
local shadowMsgEvents  = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ShadowMsgEvents")
local msgEvent         = shadowMsgEvents:WaitForChild("ShadowMsg")
local msgSequenceEvent = shadowMsgEvents:WaitForChild("ShadowMsgSequence")

--- // MAIN
msgEvent.OnClientEvent:Connect(ShadowMsgModule.showShadowMsg)
msgSequenceEvent.OnClientEvent:Connect(ShadowMsgModule.showShadowMsgSequence)