
local MessageModule = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shadowMsgEvents        = ReplicatedStorage.RemoteEvents.ShadowMsgEvents
local shadowMsgEvent         = shadowMsgEvents.ShadowMsg
local shadowMsgSequenceEvent = shadowMsgEvents.ShadowMsgSequence

type MessageEntry = {
    message: string,
    cframe: CFrame?,
    target: Instance?
}	

-- @param msGtitle: If nil, title text label will be hadden in the UI on the client
-- @param style: 'Typewriter' (letters appear one by one), 'Fade' (text slowly fades in), "Instant" (text instantly appears) - Defaults to instant
-- @param msgCFrame: If provided, client camera will change to this CFrame in the 3D world
-- @param msgTarget: If provided, client camera will follow this Instance in the 3D world (takes priority over msgCFrame)
function MessageModule.SendShadowMessage(player, msgTitle: string?, msgText, style: string?, msgCFrame: CFrame?, msgTarget: Instance?)
	if (not msgTitle and not msgText) or (msgTitle == "" and msgText == "") then
        warn("MessageSystem | SendShadowMessage: Missing msgTitle & msgText params! Returning.")
        return
    end

	if not style or style == "" then
		style = "Instant"
	end

	shadowMsgEvent:FireClient(player, msgTitle, msgText, style, msgCFrame, msgTarget)
end

-- @param msGtitle: If nil, title text label will be hadden in the UI on the client
-- @param msgTable: Table of strings to display in sequence, each entry can also contain a CFrame or target Instance for the camera to focus on
-- @param style: 'Typewriter' (letters appear one by one), or 'Fade' (text slowly fades in), "Instant" (text instantly appears) - Defaults to instant
function MessageModule.SendShadowMessageSequence(player, msgTitle: string?, msgTable : {MessageEntry}, style: string?)
	local paramType = typeof(msgTable)
	if paramType ~= "table" then
        warn("MessageSystem | SendShadowMessageSequence: Invalid msgTable param type:", paramType, msgTable, " - Returning.")
        return
    end

	if (not msgTitle and not msgTable) or (msgTitle == "" and #msgTable == 0) then
        warn("MessageSystem | SendShadowMessage: Missing msgTitle & msgTable params! Returning.")
        return
    end

	-- Override style if it's nil
	if not style or style == "" then
		style = "Instant"
	end

	shadowMsgSequenceEvent:FireClient(player, msgTitle, msgTable, style)
end

return MessageModule
