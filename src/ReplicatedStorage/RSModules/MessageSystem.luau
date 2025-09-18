
local module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shadowMsgEvents        = ReplicatedStorage.RemoteEvents.ShadowMsgEvents
local shadowMsgEvent         = shadowMsgEvents.ShadowMsg
local shadowMsgSequenceEvent = shadowMsgEvents.ShadowMsgSequence

-- @param msGtitle: If nil, title text label will be hadden in the UI on the client
-- @param style: 'Typewriter' (letters appear one by one), 'Fade' (text slowly fades in), "Instant" (text instantly appears) - Defaults to instant
function module.SendShadowMessage(player, msgTitle, msgText, style)
	if (not msgTitle and not msgText) or (msgTitle == "" and msgText == "") then
        warn("MessageSystem | SendShadowMessage: Missing msgTitle & msgText params! Returning.")
        return
    end

	if not style or style == "" then
		style = "Instant"
	end

	shadowMsgEvent:FireClient(player, msgTitle, msgText, style)
end

-- @param style: 'Typewriter' (letters appear one by one), or 'Fade' (text slowly fades in), "Instant" (text instantly appears) - Defaults to instant
function module.SendShadowMessageSequence(player, msgTitle : string, msgTable : {"number"}, style : string)
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

return module
