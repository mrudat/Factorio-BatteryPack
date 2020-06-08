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

local burnt_equipment_by_equipment
local equipment_by_burnt_equipment

local function build_equipment_by_equipment()
  burnt_equipment_by_equipment = {}
  equipment_by_burnt_equipment = {}

  for _,item in pairs(game.get_filtered_item_prototypes{
    { filter="fuel-category", ["fuel-category"]=BatteryPack.fuel_category }
  }) do
    local equipment = item.place_as_equipment_result
    if not equipment then goto next_item end

    local burnt_item = item.burnt_result
    if not burnt_item then goto next_item end

    local burnt_equipment = burnt_item.place_as_equipment_result
    if not burnt_equipment then goto next_item end

    local equipment_name = equipment.name
    local burnt_equipment_name = burnt_equipment.name

    burnt_equipment_by_equipment[equipment_name] = burnt_equipment_name
    equipment_by_burnt_equipment[burnt_equipment_name] = equipment_name
    ::next_item::
  end
end

local function get_burnt_equipment_by_equipment(equipment_name)
  if not burnt_equipment_by_equipment then
    build_equipment_by_equipment()
  end
  return burnt_equipment_by_equipment[equipment_name]
end

local function get_equipment_by_burnt_equipment(burnt_equipment_name) -- luacheck: ignore
  if not equipment_by_burnt_equipment then
    build_equipment_by_equipment()
  end
  return equipment_by_burnt_equipment[burnt_equipment_name]
end

script.on_event(defines.events.on_player_placed_equipment, function(event)
  local equipment = event.equipment
  local charged_battery_pack = equipment.name

  local battery_pack = get_burnt_equipment_by_equipment(charged_battery_pack)
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

--[[ TODO method for returning fully-charged batteries.
script.on_event(defines.events.on_gui_opened, function(event)
  local gui_type = event.gui_type
  if not gui_type == defines.gui_type.equipment then return end

  local entity = event.entity
  if not entity then return end

  local grid = entity.grid
  if not grid then return end

  -- player.print('So... you opened an equipment grid, then?')
end)
]]