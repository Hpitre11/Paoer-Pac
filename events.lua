
local M = {}

function M.add(delay, callback, name) end

function M.cancel(event_id) end

function M.update(dt) end

local selfname = debug.getinfo(1).source
if not global_singleton then global_singleton = {} end
if global_singleton[selfname] then return global_singleton[selfname] end
global_singleton[selfname] = M

local clock = 0
local next_number_id = 1
local event_ids_by_time = {}  
local events_by_id = {}  
local event_ids_by_name = {}

local function insert(event_id)
  local event = events_by_id[event_id]
  local e = event_ids_by_time
  local i = 1
  while i <= #e and events_by_id[e[i]].time < event.time do
    i = i + 1
  end
  table.insert(event_ids_by_time, i, event_id)
end

local function remove(event_id)
  local e = event_ids_by_time
  for i = 1, #e do
    if e[i] == event_id then
      table.remove(event_ids_by_time, i)
      return
    end
  end
end

function M.add(delay, callback, name)
  event_id = next_number_id
  next_number_id = next_number_id + 1
  if name then event_ids_by_name[name] = event_id end
  local event = {time = clock + delay, callback = callback, name = name}
  events_by_id[event_id] = event
  insert(event_id)
  return event_id
end

function M.cancel(event_id)
  if type(event_id) == 'string' then
    event_id = event_ids_by_name[event_id]
  end
  local e = events_by_id[event_id]
  if e == nil then return end
  if e.name and event_ids_by_name[e.name] == event_id then
    event_ids_by_name[e.name] = nil
  end
  remove(event_id)
  events_by_id[event_id] = nil
end

function M.update(dt)
  clock = clock + dt
  local e = event_ids_by_time
  while #e > 0 and events_by_id[e[1]].time < clock do
    events_by_id[e[1]].callback()
    M.cancel(e[1])
  end
end

return M

