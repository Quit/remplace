local CallHandler = class()
local Color4 = _radiant.csg.Color4
local Cube3 = _radiant.csg.Cube3
local Point3 = _radiant.csg.Point3

function CallHandler:select_area(session, response)
  stonehearth.selection:select_xz_region():require_supported(true):use_outline_marquee(Color4(255, 255, 255, 32), Color4(120, 120, 120, 255)):set_cursor 'remplace:cursors:select_area':set_find_support_filter(function(result)
      if result.entity:get_component 'terrain' then
        return true
      end

      return stonehearth.selection.FILTER_IGNORE
    end):done(function(selector, box)
      _radiant.call('remplace:get_items_within_area', box)
      :done(function(r)
        response:resolve(r)
      end)
      :fail(function()
        response:reject 'no items'
      end)
    end):fail(function(selector)
      response:reject 'no region'
    end):go()
end

local replace_bulletin

function CallHandler:get_items_within_area(session, response, box)
  local min, max = box.min, box.max
  local entities = radiant.terrain.get_entities_in_cube(Cube3(Point3(min.x, min.y, min.z), Point3(max.x, max.y, max.z)))
  
  local items = {}
  for _, entity in pairs(entities) do
    -- Make sure we'll only replace valid items
    local efc = entity:get_component('stonehearth:entity_forms')
    if radiant.entities.get_player_id(entity) == session.player_id and efc and not efc:should_hide_placement_ui() and not efc:get_should_restock() then
      local uri = entity:get_uri()
      local entity_group = items[uri]
      
      if not entity_group then
        local unit_info = entity:get_component 'unit_info'
        -- We don't set a category. Or probably one thousand other, equally important things.
        entity_group = {
          uri = uri,
          display_name = unit_info:get_display_name(),
          icon = unit_info:get_icon(),
          num = 0,
          category = 'Placed items',
          items = {}
        }
        
        items[uri] = entity_group
      end
      
      entity_group.num = entity_group.num + 1
      table.insert(entity_group.items, entity)
    end
  end
  
  -- No items found?
  if next(items) == nil then
    response:reject 'no items'
  else
    response:resolve({ items = items })
  end
end

function CallHandler:get_available_items(session, response)
  local items = {}
  for uri, item in pairs(stonehearth.inventory:get_inventory(session.player_id):get_item_tracker 'stonehearth:basic_inventory_tracker':get_tracking_data()) do
    local _, example_item = next(item.items)
    if example_item and example_item:get_component 'stonehearth:iconic_form' then
      table.insert(items, { uri = item.uri, display_name = item.display_name, icon = item.icon, num = item.count, category = 'Available items' })
    end
  end
  
  response:resolve({ items = items })
end

-- NOTE:
-- It would be so much nicer if we could simply call the call handlers to deal with this stuff...
-- but alas, I don't think we can actually "forward" calls.
function CallHandler:replace_items(session, response, items, replaceeUri)
  for _, entity in pairs(items) do
    remplace:replace_entity(session.player_id, entity, replaceeUri)
  end
end

return CallHandler