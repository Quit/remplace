-- ASKDLSAFLHSALFHSLFJHLAJHSGKLJHGLASFD!!!!!!! 
local Replacer = class()

local function count(t)
  local n = 0
  for _, _ in pairs(t) do
    n = n + 1
  end
  
  return n
end

function Replacer:initialize(player_id)
  if not self._sv.initialized then
    self._sv.initialized = true
    self._sv.player_id = player_id
    self._sv.keeper = radiant.entities.create_entity(nil, { owner = player_id })
    self._sv.replacements = {} -- replace => { replacee, replacer, location, facing, *tracers* }
    self.__saved_variables:mark_changed()
  end
end

function Replacer:restore()
  -- We need to be executed after all others, yada yada kind of thing.
  radiant.events.listen_once(radiant, 'radiant:game_loaded', function() radiant.events.listen_once(radiant, 'radiant:game_loaded', self, self._on_game_loaded) end)
end

function Replacer:_on_game_loaded()
  -- Reinstall the tracers.
  self:_install_tracers(nil, true)
end

function Replacer:destroy()
  self:_uninstall_tracers()
end

function Replacer:_install_tracers(data, by_loading)
  if not data then
    for _, replacement in pairs(self._sv.replacements) do
      self:_install_tracers(replacement, by_loading)
    end
  else
    data._position_trace = radiant.entities.trace_location(data.replacee, 'remplace'):on_changed(function()
      self:_on_position_changed(data)
    end)
    
    local efc = data.replacee:get_component 'stonehearth:entity_forms'
    
    -- Because the component does this 1s after being loaded...
    radiant.set_realtime_timer(by_loading and 1001 or 1, function()
      if efc._overlay_effect then
        efc._overlay_effect:stop()
        efc._overlay_effect = radiant.effects.run_effect(data.replacee, '/remplace/data/remplace_overlay_effect.json')
      end    
    end)
    
    -- Acquire a lease, for what it's worth.
    self:_acquire_replacement(data.replacer)
    local new_efc = data.replacer:get_component 'stonehearth:iconic_form':get_root_entity():get_component 'stonehearth:entity_forms'
    
    -- Ugh.
    new_efc:cancel_placement_tasks()
    
    -- This is such a nasty hack, but curently, the game ignores leases (at least, the inventory does)
    -- So we have to make sure that it's not picked up by someone else.
    new_efc._sv.placing_at = {
      location = data.location,
      rotation = data.facing,
    }
    
    assert(new_efc:is_being_placed(), 'fake-leasing failed')
  end
end

function Replacer:_uninstall_tracers(data)
  if not data then
    for _, replacement in pairs(self._sv.replacements) do
      self:_uninstall_tracers(replacement)
    end
  else
    if data._position_trace then
      data._position_trace:destroy()
    end
  end
end

function Replacer:_on_position_changed(data)
  if not radiant.entities.exists_in_world(data.replacee) then
    print('start replacing', data.replacee, 'with', data.replacer)
    self:_release_replacement(data.replacer)
    local ic = data.replacer:get_component 'stonehearth:iconic_form'
    --       what u did there
    local root = ic:get_root_entity()
    radiant.entities.set_player_id(root, self._sv.player_id)
    root:get_component 'stonehearth:entity_forms':place_item_on_ground(data.location, data.facing)
    
    self:_uninstall_tracers(data)
    self._sv.replacements[data.replacee:get_id()] = nil
    self.__saved_variables:mark_changed()
  end
end

function Replacer:_is_valid_replacer(entity)
  print('can_acquire_lease', entity)
  return stonehearth.ai:can_acquire_ai_lease(entity, self._sv.keeper)
end

function Replacer:_acquire_replacement(entity)
  print('acquire_lease', entity)
  return stonehearth.ai:acquire_ai_lease(entity, self._sv.keeper)
end

function Replacer:_release_replacement(entity)
  print('release_lease', entity)
  stonehearth.ai:release_ai_lease(entity, self._sv.keeper)
  entity:get_component 'stonehearth:iconic_form':get_root_entity():get_component 'stonehearth:entity_forms':cancel_placement_tasks()
  
--~   assert(self:_is_valid_replacer(entity), 'could not release lease properly?')
end

function Replacer:replace_entity(entity, replacerUri)
  -- Make sure the entity is still relevant.
  local loc = radiant.entities.get_world_grid_location(entity)
  
  if loc then
    -- Find a replacer
    local replacer = stonehearth.inventory:get_inventory(self._sv.player_id):find_closest_unused_placable_item(replacerUri, loc)
    -- No replacer found anymore? I, I just died in this call tonight, it musthavebeen something you've passed, I shouldn't have gone awaaay
    if not replacer then
      return
    end
    
    local ic = replacer:get_component 'stonehearth:iconic_form'
    
    -- Can we acquire a lease?
    if not self:_is_valid_replacer(replacer) or not ic then
      return
    end
    
    -- Undeploy the current one immediately
    local efc = entity:get_component 'stonehearth:entity_forms'
    if not efc then
      error('entity does not contain a entity_forms component')
    end
    
    -- Make sure this entity isn't already being replaced
    if efc:get_should_restock() then
      return
    end
    
    local replacer_efc = ic:get_root_entity():get_component 'stonehearth:entity_forms'
    
    if not replacer_efc or replacer_efc:is_being_placed() then
      return
    end
    
    -- But first, get the rotation
    local rot = entity:get_component('mob'):get_facing()
    
    -- Get rid of this one...
    efc:set_should_restock(true)
    
    local data = {
      replacee = entity,
      replacer = replacer,
      location = loc,
      facing = rot
    }

    print('schedule replacing of', entity, 'with', replacer)
    self._sv.replacements[entity:get_id()] = data
    self:_install_tracers(data)
    self.__saved_variables:mark_changed()
  end
end

return Replacer