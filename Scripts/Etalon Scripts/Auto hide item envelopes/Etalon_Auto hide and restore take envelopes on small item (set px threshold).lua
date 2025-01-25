-- @description Auto Hide Envelope Settings
-- @author Etalon
-- @version 1.0
-- @about Change height threshold for auto-hiding envelopes
-- @noindex false

local script_path = debug.getinfo(1,'S').source:match([[^@?(.*[\\/])[^\\/]-$]])
local retval, height = reaper.GetUserInputs("Auto Hide Envelope Settings", 1, "Minimum height (px):", "28")

if retval and tonumber(height) and tonumber(height) > 0 then
   local file = io.open(script_path .. "autohide_config.txt", "w")
   if file then
       file:write(height)
       file:close()
       reaper.MB("Height threshold updated to " .. height .. "px", "Settings Updated", 0)
   end
else
   reaper.MB("Please enter a valid positive number", "Error", 0)
end