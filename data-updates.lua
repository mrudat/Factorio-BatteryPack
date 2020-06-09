local ORNodes = require('__OR-Nodes__/library.lua').init()
local rusty_locale = require('__rusty-locale__/locale')
local rusty_icons = require('__rusty-locale__/icons')

local locale_of = rusty_locale.of
local icons_of = rusty_icons.of

--[[ NOTES:
names of things:
fuel-item: <prefix>-<battery>-charged
equipment: <prefix>-<equipment>-charged
charger/discharger:
<prefix>-charger-<rate>
<prefix>-discharger-<rate>

-- vehicles
-- TODO respect energy_source.input_flow_limit and output_flow_limit?
-- would need a fuel_category for each value of output_flow_limit and a charging_recipe_category for each value of input_flow_limit
-- perhaps not necessary; the smallest battery allows 200MW, which is way more than any vehicle we're likely to run into.

]]

-- other values we're going to be using later

local battery_icons = icons_of(data.raw.item.battery)

function BatteryPack.process_batteries()
  local new_things = {}
  local processed_items = {}
  for _, battery in pairs(data.raw["battery-equipment"]) do
    BatteryPack.process_battery(battery, new_things, processed_items)
  end
  if next(new_things) then
    data:extend(new_things)
  end
  local battery_charger_prerequisite = ORNodes.depend_on_items(processed_items)[1]
  if battery_charger_prerequisite then
    local battery_charger_prerequisites = data.raw.technology[BatteryPack.battery_charger_technology].prerequisites
    battery_charger_prerequisites[#battery_charger_prerequisites + 1] = battery_charger_prerequisite
    local battery_power_plant_prerequisites = data.raw.technology[BatteryPack.battery_power_plant].prerequisites
    battery_power_plant_prerequisites[#battery_power_plant_prerequisites + 1] = battery_charger_prerequisite
  end
end

local function set_item_fuel_properties(item, fuel_value, burnt_result)
  item.fuel_category = BatteryPack.fuel_category
  item.burnt_result = burnt_result
  item.fuel_value = fuel_value
  -- TODO same as nuclear fuel, but perhaps could be better?
  item.fuel_acceleration_multiplier = 2.5
  item.fuel_top_speed_multiplier = 1.15
  -- batteries are clean, we already paid for the pollution wherever the power was generated
  item.fuel_emissions_multiplier = 0.0
end

function BatteryPack.process_battery(old_battery_equipment, new_things, processed_items)
  if BatteryPack.equipment_blacklist[old_battery_equipment.name] then return end

  local old_battery_item = BatteryPack.find_item_that_places_equipment(old_battery_equipment)
  if not old_battery_item then return end

  local old_battery_item_name = old_battery_item.name
  if BatteryPack.item_blacklist[old_battery_item_name] then return end

  -- this is alredy usable as fuel, don't touch this
  if old_battery_item.fuel_category then return end

  local energy_source = old_battery_equipment.energy_source
  local buffer_capacity = energy_source.buffer_capacity

  if (BatteryPack.primary_batteries[old_battery_item_name]) then
    set_item_fuel_properties(old_battery_item, buffer_capacity, nil)
    table.insert(new_things, old_battery_item)
    return
  end

  if energy_source.usage_priority ~= "tertiary" then return end

  local joules_in_battery = util.parse_energy(buffer_capacity)
  local time_to_fill_battery = joules_in_battery / BatteryPack.CHARGER_POWER

  if time_to_fill_battery <= 0.001 then
    log("Not producing a fully charged version of the " .. old_battery_item_name)
    return
  end

  local technology_list = ORNodes.depend_on_item(old_battery_item.name, old_battery_item.type, true)
  if not technology_list then return end
  local start_enabled = true
  if technology_list[1] then
    start_enabled = false
  end

  -- Start creating new things here.

  local battery_equipment = table.deepcopy(old_battery_equipment)
  local battery_item = table.deepcopy(old_battery_item)

  local old_battery_equipment_name = old_battery_equipment.name

  local battery_equipment_name = BatteryPack.PREFIX .. old_battery_equipment_name .. "-charged"
  local battery_item_name = BatteryPack.PREFIX .. old_battery_item.name .. "-charged"

  local old_battery_localised_name = locale_of(old_battery_item).name

  battery_equipment.name = battery_equipment_name
  battery_equipment.localised_name = { -- doesn't seem to be used?
    BatteryPack.MOD_NAME .. ".charged",
    old_battery_localised_name
  }

  battery_item.name = battery_item_name
  battery_item.localised_name = { -- but the original item doesn't have a localised name?
    BatteryPack.MOD_NAME .. ".charged",
    old_battery_localised_name
  }
  battery_item.placed_as_equipment_result = battery_equipment_name
  set_item_fuel_properties(battery_item, buffer_capacity, old_battery_item_name)

  -- make uncharged battery darker than charged battery
  local discharged_icons = BatteryPack.discharged_icons
  discharged_icons = discharged_icons[old_battery_equipment_name]
  if not discharged_icons then
    local discharged_overlays = BatteryPack.discharged_overlays
    local discharged_overlay = discharged_overlays[old_battery_equipment_name]
    if not discharged_overlay then
      local shape = old_battery_equipment.shape
      discharged_overlay = discharged_overlays[shape.height .. "x" .. shape.width]
      if not discharged_overlay then
        discharged_overlay = discharged_overlays['default']
      end
    end

    discharged_icons = util.combine_icons(icons_of(old_battery_item), discharged_overlay, {})
  end
  old_battery_item.icons = discharged_icons

  local charge_recipe = {
    type = "recipe",
    name = battery_item_name,
    category = BatteryPack.charging_recipe_category,
    ingredients = {
      {
        type = "item",
        name = old_battery_item_name,
        amount = 1
      }
    },
    results = {
      {
        type = "item",
        name = battery_item_name,
        amount = 1
      }
    },
    energy_required = time_to_fill_battery,
    enabled = start_enabled,
    allow_decomposition = false,
    allow_as_intermediate = false,
    allow_intermediates = false,
  }

  if not start_enabled then
    table.insert(
      data.raw.technology[technology_list[1]].effects,
      { type = "unlock-recipe", recipe = battery_item_name }
    )
  end

  -- TODO build charger/discharger to match battery?

  processed_items[#processed_items+1] = old_battery_item

  table.insert(new_things, charge_recipe)
  table.insert(new_things, battery_equipment)
  table.insert(new_things, battery_item)
end

function BatteryPack.process_vehicles()
  local new_things = {}
  local processed_items = {}
  for _,car in pairs(data.raw["car"]) do
    BatteryPack.process_vehicle(car, new_things, processed_items)
  end
  for _,locomotive in pairs(data.raw["locomotive"]) do
    BatteryPack.process_vehicle(locomotive, new_things, processed_items)
  end
  if next(new_things) then
    data:extend(new_things)
  end
  local electric_vehicle_prerequisite = ORNodes.depend_on_items(processed_items)[1]
  if electric_vehicle_prerequisite then
    local electric_vehicle_prerequisites = data.raw.technology[BatteryPack.electric_vehicle_technology].prerequisites
    electric_vehicle_prerequisites[#electric_vehicle_prerequisites + 1] = electric_vehicle_prerequisite
  end
end

-- TODO intermediate hybrid version?
function BatteryPack.process_vehicle(old_vehicle, new_things, processed_items)
  local old_item = BatteryPack.find_item_that_places_vehicle(old_vehicle)
  if not old_item then return end

  local old_item_name = old_item.name
  if not old_item_name then return end

  local engines = BatteryPack.find_engines_for_item_name(old_item_name)

  local old_vehicle_name = old_vehicle.name

  if BatteryPack.vehicle_blacklist[old_vehicle_name] then return end

  local parent_tech = ORNodes.depend_on_item(old_item.name, old_item.type, true)
  if not parent_tech then return end

  local burner = old_vehicle.burner

  if not burner then
    burner = old_vehicle.energy_source
    if not burner then return end
    if burner.type ~= "burner" then return end
  end

  local fuel_inventory_size = burner.fuel_inventory_size
  if fuel_inventory_size == 0 then return end

  local fuel_category = burner.fuel_category
  if fuel_category then
    if fuel_category ~= 'chemical' then return end
  else
    local fuel_categories = burner.fuel_categories
    if fuel_categories then
      local has_chemical = false
      for _, fuel_category in pairs(fuel_categories) do -- luacheck: ignore
        if fuel_category == BatteryPack.fuel_category then return end
        if fuel_category == 'chemical' then
          has_chemical = true
        end
      end
      if not has_chemical then return end
    end
  end

  ---------------------------------------------------------------
  -- Start creating new things here.

  local vehicle = table.deepcopy(old_vehicle)
  local item = table.deepcopy(old_item)

  local electric_vehicle_name = BatteryPack.PREFIX .. old_vehicle.name

  local recipe = {
    type = "recipe",
    name = electric_vehicle_name,
    main_product = electric_vehicle_name,
    ingredients = {
      {
        type = "item",
        name = old_item_name,
        amount = 1
      },
      {
        type = "item",
        name = "electronic-circuit",
        amount = 5
      },
      {
        type = "item",
        name = BatteryPack.PREFIX .. "battery-holder",
        amount = 1
      },
    },
    results = {
      {
        type = "item",
        name = electric_vehicle_name,
        amount = 1
      },
    },
    enabled = false,
    allow_decomposition = false
  }

  local reverse_recipe_name = electric_vehicle_name .. '-reverse'

  local reverse_recipe = {
    type = "recipe",
    name = reverse_recipe_name,
    main_product = old_item_name,
    ingredients = recipe.results,
    results = recipe.ingredients,
    enabled = false,
    allow_decomposition = false
  }

  if engines[1] then
    if engines[1] == "engine-unit" then
      table.insert(recipe.ingredients,{
        type = "item",
        name = "electric-engine-unit",
        amount = engines[2],
      })
      table.insert(recipe.results,{
        type = "item",
        name = "engine-unit",
        amount = engines[2],
      })
    end
  else
    table.insert(recipe.ingredients,{
      type = "item",
      name = "electric-engine-unit",
      amount = 1,
    })
  end

  burner = vehicle.burner or vehicle.energy_source

  burner.fuel_categories = nil
  burner.fuel_category = BatteryPack.fuel_category
  burner.burnt_inventory_size = fuel_inventory_size
  burner.smoke = nil

  --vehicle.sound_minimum_speed = 0.25
  --vehicle.sound_scaling_ratio = 1.0

  local working_sound = vehicle.working_sound
  if working_sound then
    if not (working_sound.sound) then
      BatteryPack.patch_sound(vehicle, 'working_sound')
    else
      working_sound.match_volume_to_activity = true
      working_sound.match_speed_to_activity = true
      BatteryPack.patch_sound(working_sound, 'activate_sound')
      BatteryPack.patch_sound(working_sound, 'deactivate_sound')
      BatteryPack.patch_sound(working_sound, 'sound')
      if not (working_sound.sound) then
        vehicle.working_sound = nil
      end
    end
  end

  local sound_no_fuel = vehicle.sound_no_fuel
  if sound_no_fuel then
    BatteryPack.patch_sound(sound_no_fuel, 1)
    if not sound_no_fuel[1] then
      vehicle.sound_no_fuel = nil
    end
  end

  local localised_name = {
    BatteryPack.MOD_NAME .. ".battery-powered",
    locale_of(old_vehicle).name
  }

  vehicle.name = electric_vehicle_name
  vehicle.localised_name = localised_name

  local minable = vehicle.minable
  if minable then
    minable.results = nil
    minable.result = electric_vehicle_name
  end

  item.name = electric_vehicle_name
  item.place_result = electric_vehicle_name
  item.localised_name = localised_name

  local icons = {}
  icons = util.combine_icons(
    icons,
    icons_of(item),
    {
      scale = 0.75,
      shift = {3, 3}
    }
  )
  icons = util.combine_icons(
    icons,
    battery_icons,
    {
      scale = 0.5,
      shift = {-8, -8}
    }
  )
  item.icons = icons

  local item_order = item.order
  item.order = item_order .. "2"
  reverse_recipe.order = item_order .. "3"

  local technology = {
    type = "technology",
    name = electric_vehicle_name,
    localised_name = localised_name,
    icons = icons,
    unit = {
      count = 10,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
      },
      time = 15
    },
    effects = {
      { type = "unlock-recipe", recipe = electric_vehicle_name },
      { type = "unlock-recipe", recipe = reverse_recipe_name }
    },
    prerequisites = {
      BatteryPack.electric_vehicle_technology
    }
  }

  local prerequisites = technology.prerequisites

  local technology_name = parent_tech[1]
  if technology_name then
    table.insert(prerequisites, technology_name)
  end

  processed_items[#processed_items+1] = old_item

  table.insert(new_things, technology)
  table.insert(new_things, vehicle)
  table.insert(new_things, item)
  table.insert(new_things, recipe)
  table.insert(new_things, reverse_recipe)
end

function BatteryPack.patch_sound(sound, key)
  local thesound = sound[key]
  if not thesound then return end
  local volume = thesound.volume or 1
  if volume == 0 then
    sound[key] = nil
    return
  end
  local filename = sound[key].filename
  if BatteryPack.sound_blacklist[filename] then
    sound[key] = nil
    return
  end
  local replacement_sound = BatteryPack.sound_replacement[filename]
  if replacement_sound then
    if type(replacement_sound) == 'table' then
      thesound.filename = replacement_sound.filename
      thesound.volume = replacement_sound.volume
    else
      thesound.filename = replacement_sound
    end
    return
  end
end

function BatteryPack.find_engines_for_item_name(item_name)
  local item_names_seen = {}
  local recipe_queue = {}

  local function register_recipes()
    if item_names_seen[item_name] then return end

    item_names_seen[item_name] = true

    local recipe_names = BatteryPack.find_recipes_for_thing(item_name)

    if not recipe_names then return end

    for _, recipe_name in ipairs(recipe_names) do
      table.insert(recipe_queue, recipe_name)
    end
  end

  register_recipes()

  local name
  local amount

  for _,recipe_name in ipairs(recipe_queue) do
    local recipe = data.raw["recipe"][recipe_name]
    if recipe.normal then
      recipe = recipe.normal
    end
    for _,ingredient in ipairs(recipe.ingredients) do
      if ingredient.type then
        if ingredient.type == "item" then
          name = ingredient.name
          amount = ingredient.amount
        else
          goto next_ingredient
        end
      else
        name = ingredient.name or ingredient[1]
        amount = ingredient.amount or ingredient[2]
      end
      if not name then
        log("Error reading item name from ingredient: " .. serpent.line{ingredient});
        goto next_ingredient
      end

      if name == "electric-engine-unit" then
        return {
          "electric-engine-unit", amount
        }
      end

      if name == "engine-unit" then
        return {
          "engine-unit", amount
        }
      end

      register_recipes(name)
      ::next_ingredient::
    end
  end

  return {}
end

do -- TODO reset this if we get called outside this module?
  local equipment_to_item_map = nil

  local function build_item_to_equipment_map()
    equipment_to_item_map = {}

    for _, item in pairs(data.raw["item"]) do
      local equipment_name = item.placed_as_equipment_result
      if equipment_name then
        equipment_to_item_map[equipment_name] = item
      end
    end
  end

  function BatteryPack.find_item_that_places_equipment(equipment)
    if not equipment_to_item_map then
      build_item_to_equipment_map()
    end

    return equipment_to_item_map[equipment.name]
  end
end

do -- TODO reset this if we get called outside this module?
  local vehicle_to_item_map = nil

  local function build_item_to_vehicle_map()
    vehicle_to_item_map = {}

    for _, item in pairs(data.raw["item-with-entity-data"]) do
      local vehicle_name = item.place_result
      if vehicle_name then
        vehicle_to_item_map[vehicle_name] = item
      end
    end

    for _, item in pairs(data.raw["item"]) do
      local vehicle_name = item.place_result
      if vehicle_name then
        vehicle_to_item_map[vehicle_name] = item
      end
    end
  end

  function BatteryPack.find_item_that_places_vehicle(vehicle)
    if not vehicle_to_item_map then
      build_item_to_vehicle_map()
    end

    return vehicle_to_item_map[vehicle.name]
  end
end

do
  local thing_to_recipe

  local function register_result(recipe_name, thing_name)
    if not thing_to_recipe[thing_name] then
      thing_to_recipe[thing_name] = {}
    end
    table.insert(thing_to_recipe[thing_name], recipe_name)
  end

  local function build_thing_to_recipe_map()
    thing_to_recipe = {}
    for recipe_name,recipe in pairs(data.raw["recipe"]) do
      --if recipe.hidden then goto next_recipe end
      if recipe.normal then
        recipe = recipe.normal
      end
      if recipe.result then
        register_result(recipe_name, recipe.result)
      elseif recipe.results then
        for _,result in ipairs(recipe.results) do
          if result.name then
            register_result(recipe_name, result.name)
          else
            register_result(recipe_name, result[1])
          end
        end
      end
    end
  end

  function BatteryPack.find_recipes_for_thing(thing_name)
    if not thing_to_recipe then
      build_thing_to_recipe_map()
    end
    return thing_to_recipe[thing_name]
  end
end

BatteryPack.process_batteries()
BatteryPack.process_vehicles()
