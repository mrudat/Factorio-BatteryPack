local BatteryPack = {}

BatteryPack.MOD_NAME = "BatteryPack"
BatteryPack.PREFIX = BatteryPack.MOD_NAME .. "-"

BatteryPack.fuel_category = BatteryPack.PREFIX .. "category"

local function recover_battery(event)
  local entity = event.entity

  local burner  = entity.burner
  if not burner then return end
  
  local currently_burning = burner.currently_burning
  if not currently_burning then return end
  
  local fuel_category = currently_burning.fuel_category
  if not fuel_category == BatteryPack.fuel_category then return end
  
  local burnt_result = currently_burning.burnt_result
  if not burnt_result then return end
  
  local burnt_result_name = burnt_result.name

  event.buffer.insert({name=burnt_result_name, count=1})
  
  -- record that we just created a burnt_result from the remaining fuel in the burner
  entity.force.item_production_statistics.on_flow(burnt_result_name, 1)
end

script.on_event(defines.events.on_player_mined_entity, recover_battery)
script.on_event(defines.events.on_robot_mined_entity, recover_battery)

local battery_pack_data_by_equipment_name = nil

local function build_battery_pack_data_by_equipment_name()
  battery_pack_data_by_equipment_name = {}
  
  for _,equipment in pairs(game.equipment_prototypes) do
    local equipment_name = equipment.name
    
    local equipment_item = equipment.take_result
    if not equipment_item then goto next_equipment end
    
    local fuel_category = equipment_item.fuel_category
    if fuel_category ~= BatteryPack.fuel_category then goto next_equipment end
    
    local burnt_item = equipment_item.burnt_result
    if not burnt_item then goto next_equipment end
    
    local burnt_equipment = burnt_item.place_as_equipment_result
    if not burnt_equipment then goto next_equipment end
    
    local burnt_equipment_name = burnt_equipment.name
    
    battery_pack_data_by_equipment_name[equipment_name] = burnt_equipment_name
    
    ::next_equipment::
  end
end

local function get_battery_pack_data(equipment_name)
  if not battery_pack_data_by_equipment_name then
    build_battery_pack_data_by_equipment_name()
  end
  return battery_pack_data_by_equipment_name[equipment_name]
end

script.on_event(defines.events.on_player_placed_equipment, function(event)
  local equipment = event.equipment
  local charged_battery_pack = equipment.name

  local battery_pack = get_battery_pack_data(charged_battery_pack)
  if not battery_pack then return end

  local position = equipment.position
  local equipment_grid = event.grid

  -- swap charged_battery_pack with battery_pack
  equipment_grid.take{position=position}
  equipment_grid.put{name=battery_pack,position=position}
  
  -- set charge on battery_pack to full
  local new_equipment = equipment_grid.get(position)
  new_equipment.energy = new_equipment.max_energy
  
  -- record that we consumed charged_battery_pack and created a battery_pack
  local item_production_statistics = game.players[event.player_index].force.item_production_statistics
  item_production_statistics.on_flow(charged_battery_pack, -1)
  item_production_statistics.on_flow(battery_pack, 1)
end)

-- possibly should be more conservative, but this is simple and reliable
local function reset_technology_effects (event)
  for i, force in pairs(game.forces) do
    force.reset_technology_effects()
  end
end

local function on_configuration_changed(ccd)
  local mod_changes = ccd.mod_changes[BatteryPack.MOD_NAME]
  if mod_changes then
    if mod_changes.old_version then
      reset_technology_effects()
    end
  end
end

script.on_configuration_changed( reset_technology_effects )

-- reload recipes?