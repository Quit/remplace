remplace = {}

function remplace:_on_init()
  self._sv = remplace.__saved_variables:get_data()
  
  if not self._sv.replacers then
    self._sv.replacers = {}
  end
end

-- Technically, a service or maybe controller would be *much* cleaner for this kind of thing.
-- Because I don't expect the mod to stick around, however, this will suffice...
function remplace:replace_entity(player_id, entity, replacerUri)
  -- Get the controller
  local controller = self._sv.replacers[player_id]
  if not controller then
    controller = radiant.create_controller('remplace:controllers:replacer', player_id)
    self._sv.replacers[player_id] = controller
    self.__saved_variables:mark_changed()
  end
  
  controller:replace_entity(entity, replacerUri)
end

radiant.events.listen(remplace, 'radiant:init', remplace, remplace._on_init)

return remplace