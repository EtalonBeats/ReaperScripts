-- @description Auto hide and restore take envelopes on small items under cursor
-- @author Etalon
-- @version 1.0
-- @about Automatically hide envelopes when mouse hovers over small items

local last_processed_guid = nil
local envelope_states = {}
local script_path = debug.getinfo(1,'S').source:match([[^@?(.*[\\/])[^\\/]-$]])

local function getThreshold()
   local file = io.open(script_path .. "autohide_config.txt", "r")
   if file then
       local val = tonumber(file:read())
       file:close()
       return val or 28
   end
   return 28
end

function UpdateEnvelopeStates()
  local num_tracks = reaper.CountTracks(0)
  for i = 0, num_tracks - 1 do
    local track = reaper.GetTrack(0, i)
    local num_items = reaper.CountTrackMediaItems(track)
    
    for j = 0, num_items - 1 do
      local item = reaper.GetTrackMediaItem(track, j)
      local take = reaper.GetActiveTake(item)
      if take then
        local guid = reaper.BR_GetMediaItemGUID(item)
        if not envelope_states[guid] then
          envelope_states[guid] = {}
        end
        
        local env_count = reaper.CountTakeEnvelopes(take)
        for k = 0, env_count-1 do
          local env = reaper.GetTakeEnvelope(take, k)
          local br_env = reaper.BR_EnvAlloc(env, false)
          local _, visible = reaper.BR_EnvGetProperties(br_env)
          if guid ~= last_processed_guid then
            envelope_states[guid][k] = visible
          end
          reaper.BR_EnvFree(br_env, false)
        end
      end
    end
  end
end

function GetTakeHeight(take)
  if not take then return 0 end
  local item = reaper.GetMediaItemTake_Item(take)
  if not item then return 0 end
  return reaper.GetMediaItemInfo_Value(item, "I_LASTH")
end

function HideEnvelopes(take)
  if not take then return end
  local env_count = reaper.CountTakeEnvelopes(take)
  for j = 0, env_count-1 do
    local env = reaper.GetTakeEnvelope(take, j)
    local br_env = reaper.BR_EnvAlloc(env, false)
    local active, _, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
    reaper.BR_EnvSetProperties(br_env, active, false, armed, inLane, laneHeight, defaultShape, faderScaling)
    reaper.BR_EnvFree(br_env, true)
  end
end

function RestoreEnvelopeStates(take, guid)
  if not take or not envelope_states[guid] then return end
  
  local env_count = reaper.CountTakeEnvelopes(take)
  for j = 0, env_count-1 do
    local env = reaper.GetTakeEnvelope(take, j)
    local br_env = reaper.BR_EnvAlloc(env, false)
    local active, _, armed, inLane, laneHeight, defaultShape, _, _, _, _, faderScaling = reaper.BR_EnvGetProperties(br_env)
    local original_state = envelope_states[guid][j]
    if original_state == nil then
      original_state = true
    end
    reaper.BR_EnvSetProperties(br_env, active, original_state, armed, inLane, laneHeight, defaultShape, faderScaling)
    reaper.BR_EnvFree(br_env, true)
  end
end

function GetItemUnderMouse()
  local window, segment, details = reaper.BR_GetMouseCursorContext()
  local item = reaper.BR_GetMouseCursorContext_Item()
  if window == "arrange" and item then
    return item
  end
  return nil
end

function ProcessItem(item)
 if not item then return end
 local take = reaper.GetActiveTake(item)
 if not take then return end
 local item_guid = reaper.BR_GetMediaItemGUID(item)
 local take_height = GetTakeHeight(take)
 if take_height <= getThreshold() then
   HideEnvelopes(take)
   last_processed_guid = item_guid
 end
end

function RestoreLastProcessedItem()
  if last_processed_guid and envelope_states[last_processed_guid] then
    local item = reaper.BR_GetMediaItemByGUID(0, last_processed_guid)
    if item then
      local take = reaper.GetActiveTake(item)
      if take then
        RestoreEnvelopeStates(take, last_processed_guid)
      end
    end
    last_processed_guid = nil
  end
end

function Main()
 local item = GetItemUnderMouse()
 local threshold = getThreshold()
 
 if item then
   local current_guid = reaper.BR_GetMediaItemGUID(item)
   local take = reaper.GetActiveTake(item)
   
   if take then
     local take_height = GetTakeHeight(take)
     if take_height > threshold or current_guid ~= last_processed_guid then
       RestoreLastProcessedItem()
     end
     if take_height <= threshold then
       ProcessItem(item)
     end
   end
 else
   RestoreLastProcessedItem()
 end
 
 UpdateEnvelopeStates()
 reaper.defer(Main)
end

reaper.defer(Main)