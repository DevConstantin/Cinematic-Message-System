-- This module fires events to the client, allowing the client to see cinematic messages. It also performs a variety of input validation to ensure that message events are fired correctly

local CinematicMessageService = {}

--- // SERVICES
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--- // OBJECTS
-- RemoteEvents
local cinematicMsgEvents = ReplicatedStorage.RemoteEvents.ShadowMsgEvents
local msgEvent = cinematicMsgEvents.ShadowMsg
local msgSequenceEvent = cinematicMsgEvents.ShadowMsgSequence

type MessageEntry = {
    message: string?,
    cframe: CFrame?,
    target: Instance?
}	

--- // FUNCTIONS

-- Sends a cinematic message to a specific player
-- You must provide either msgText, msgCFrame, or msgTarget 
-- @param msgTitle: If nil, title text label will be hadden in the UI on the client, otherwise displayed above the message text
-- @param style: 'Typewriter' (letters appear one by one), 'Fade' (text slowly fades in), "Instant" (text instantly appears) - Defaults to instant
-- @param msgCFrame: If provided, client camera will change to this CFrame in the 3D world
-- @param msgTarget: If provided, client camera will follow this Instance in the 3D world (takes priority over msgCFrame)
function CinematicMessageService.sendCinematicMessage(player: Player, msgTitle: string?, msgText: string?, style: string?, msgCFrame: CFrame?, msgTarget: Instance?)
	-- Validate parameters
	if (msgText == nil or msgText == "") and msgCFrame == nil and msgTarget == nil then
		warn("CinematicMessageService | SendCinematicMessage: Missing msgText, msgCFrame, and msgTarget params! Returning.")
		return
	end

	if msgTitle ~= nil and typeof(msgTitle) ~= "string" then
		warn("CinematicMessageService | SendCinematicMessage: Invalid msgTitle param type:", typeof(msgTitle), msgTitle, " - Returning.")
		return
	end

	if msgText ~= nil and typeof(msgText) ~= "string" then
		warn("CinematicMessageService | SendCinematicMessage: Invalid msgText param type:", typeof(msgText), msgText, " - Returning.")
		return
	end
	
	-- Override style if it's nil
	if not style or style == "" then
		style = "Instant"
	end

	msgEvent:FireClient(player, msgTitle, msgText, style, msgCFrame, msgTarget)
end

-- Sends a sequence of cinematic messages to a specific player
-- @param msgTitle: If nil, title text label will be hadden in the UI on the client
-- @param msgTable: Table of strings to display in sequence, formatted as follows:
-- {
--     {message = "First message", cframe = CFrame.new(0, 10, 0), target = nil}, -- cframe and target are optional
--     {message = "Second message", cframe = nil, target = workspace.SomePart},
--     {message = "Third message", cframe = nil, target = nil}
-- }
-- @param style: 'Typewriter' (letters appear one by one), or 'Fade' (text slowly fades in), "Instant" (text instantly appears) - Defaults to instant
function CinematicMessageService.sendCinematicMessageSequence(player: Player, msgTitle: string?, msgTable: { MessageEntry }, style: string?)
	if msgTitle ~= nil and typeof(msgTitle) ~= "string" then
		warn("MessageSystem | SendCinematicMessageSequence: Invalid msgTitle param type:", typeof(msgTitle), msgTitle, " - Returning.")
		return
	end
	
	local paramType = typeof(msgTable)
	if paramType ~= "table" then
        warn("MessageSystem | SendCinematicMessageSequence: Invalid msgTable param type:", paramType, msgTable, " - Returning.")
        return
    end

	if #msgTable == 0 then
		warn("MessageSystem | SendCinematicMessageSequence: msgTable param is empty! Returning.")
		return
	end

	-- Override style if it's nil
	if not style or style == "" then
		style = "Instant"
	end

	msgSequenceEvent:FireClient(player, msgTitle, msgTable, style)
end

-- Sends a cinematic message and a series of Vector3 points that define a curve path for the camera to follow
-- @param msgTitle: If nil, title text label will be hadden in the UI on the client, otherwise displayed above the message text
-- @param msgText: The message text to display	
-- @param vector3Points: A table of Vector3 points that define the curve path
-- @param style: 'Typewriter' (letters appear one by one), 'Fade' (text slowly fades in), "Instant" (text instantly appears) - Defaults to instant
function CinematicMessageService.sendCinematicMessageWithCurve(player: Player, msgTitle: string?, msgText: string, vector3Points : { Vector3 },  style: string?)
	-- Validate parameters
	if msgText == "" or msgText == nil then
		warn("CinematicMessageService | SendCinematicMessageWithCurve: Missing msgText param! Returning.")
		return
	end

	local msgParamType = typeof(msgText)
	if msgParamType ~= "string" then
		warn("CinematicMessageService | SendCinematicMessageWithCurve: Invalid msgText param type:", msgParamType, msgText, " - Returning.")
		return
	end

	local pointsParamType = typeof(vector3Points)
	if pointsParamType ~= "table" then
		warn("CinematicMessageService | SendCinematicMessageWithCurve: Invalid vector3Points param type:", pointsParamType, vector3Points, " - Returning.")
		return
	end

	if #vector3Points < 2 then
		warn("CinematicMessageService | SendCinematicMessageWithCurve: vector3Points param has less than 2 points! Returning.")
		return
	end
	
	-- Override style if it's nil
	if not style or style == "" then
		style = "Instant"
	end

	msgEvent:FireClient(player, msgTitle, msgText, style, nil, nil, vector3Points)
end

return CinematicMessageService
