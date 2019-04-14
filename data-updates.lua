--[[ NOTES:
names of things:
fuel-item: <prefix>-<battery>-charged
equipment: <prefix>-<equipment>-charged
charger/discharger:
<prefix>-charger-<rate>
<prefix>-discharger-<rate>

-- vehicles
-- TODO duplicate any fuel-burning vehicle and adjust stats accordingly
-- TODO if pollution multiplier is set to 0 (rather than default 1, does it stop the burner from emitting pollution, and if so, can we merely edit something that uses electric-engine-unit to use our fuel directly?)
-- TODO swap out any engine for electric-engine-unit, ie. take existing vehicle and n electric-engine units, and return new vehicle + n engine.

-- TODO respect energy_source.input_flow_limit and output_flow_limit?
-- would need a fuel_category for each value of output_flow_limit and a charging_recipe_category for each value of input_flow_limit
-- perhaps not necessary; the smallest battery allows 200MW, which is way more than any vehicle we're likely to run into.

]]

-- Modules

BatteryPack = {}

-- Constants

BatteryPack.MOD_NAME = "BatteryPack"
BatteryPack.PREFIX = BatteryPack.MOD_NAME .. "-"
BatteryPack.MOD_DIRECTORY = "__" .. BatteryPack.MOD_NAME .. "__/"
BatteryPack.GRAPHICS_DIRECTORY = BatteryPack.MOD_DIRECTORY .. "graphics/"

-- other values we're going to be using later

BatteryPack.CHARGER_POWER = 200 * 1000 * 1000 -- 200MW (max power battery-equipment)

BatteryPack.fuel_category = BatteryPack.PREFIX .. "category"
BatteryPack.charging_recipe_category = BatteryPack.PREFIX .. "charging"

function BatteryPack.process_batteries()
  local new_things = {}
  for battery_name, battery in pairs(data.raw["battery-equipment"]) do
    -- TODO if added by ModularChargePacks, don't touch?
    BatteryPack.process_battery(battery, new_things)
  end
  if next(new_things) then
    data:extend(new_things)
  end
end

BatteryPack.discharged_overlays = {
  ["2x1"] = true,
  ["1x1"] = true,
}

function BatteryPack.process_battery(old_battery_equipment, new_things)

  local old_battery_item_name = BatteryPack.find_item_that_places_equipment(old_battery_equipment)
  if not old_battery_item_name then return end

  local old_battery_item = data.raw["item"][old_battery_item_name]
  if not old_battery_item then return end

  -- this is alredy usable as fuel, don't touch this
  if old_battery_item.fuel_category then return end

  local energy_source = old_battery_equipment.energy_source

  if energy_source.usage_priority ~= "tertiary" then return end

  local buffer_capacity = energy_source.buffer_capacity
  local joules_in_battery = BatteryPack.energy_to_joules(buffer_capacity)
  local time_to_fill_battery = joules_in_battery / BatteryPack.CHARGER_POWER

  if time_to_fill_battery <= 0.001 then
    log("Not producing a fully charged version of the " .. old_battery_item_name)
    return
  end

  local technology_list = BatteryPack.find_technologies_for_item(old_battery_item_name)
  local start_enabled = true
  if next(technology_list) then
    start_enabled = false
  end

  local height = old_battery_equipment.shape.height
  local width = old_battery_equipment.shape.width
  local overlay_size = height .. "x" .. width
  local discharged_overlay = BatteryPack.GRAPHICS_DIRECTORY .. "dark-overlay.png"
  if BatteryPack.discharged_overlays[overlay_size] then
    discharged_overlay = BatteryPack.GRAPHICS_DIRECTORY .. "dark-overlay-" .. overlay_size .. ".png"
  end

  -- Start creating new things here.

  local battery_equipment = table.deepcopy(old_battery_equipment)
  local battery_item = table.deepcopy(old_battery_item)

  old_battery_equipment_name = old_battery_equipment.name

  local battery_equipment_name = BatteryPack.PREFIX .. old_battery_equipment_name .. "-charged"
  local battery_item_name = BatteryPack.PREFIX .. old_battery_item.name .. "-charged"

  battery_equipment.name = battery_equipment_name
  battery_equipment.localised_name = { -- doesn't seem to be used?
    BatteryPack.MOD_NAME .. ".charged",
    {
      "equipment-name." .. old_battery_equipment_name
    }
  }

  battery_item.name = battery_item_name
  battery_item.localised_name = { -- but the original item doesn't have a localised name?
    BatteryPack.MOD_NAME .. ".charged",
    {
      "equipment-name." .. old_battery_equipment_name
    }
  }
  battery_item.placed_as_equipment_result = battery_equipment_name
  battery_item.fuel_category = BatteryPack.fuel_category
  battery_item.burnt_result = old_battery_item_name
  battery_item.fuel_value = buffer_capacity
  -- TODO same as nuclear fuel, but perhaps could be better?
  battery_item.fuel_acceleration_multiplier = 2.5
  battery_item.fuel_top_speed_multiplier = 1.15
  -- batteries are clean, we already paid for the pollution wherever the power was generated
  battery_item.fuel_emissions_multiplier = 0.0

  -- make uncharged battery darker than charged battery
  BatteryPack.add_icons(
    old_battery_item,
    {
      {
        icon = discharged_overlay,
        tint = { r=0, g=0, b=0, a=0.6 },
        icon_size = 32
      }
    }
  )

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

  BatteryPack.add_recipe_to_technologies(battery_item_name, technology_list)

  -- TODO build charger/discharger to match battery?

  table.insert(new_things, charge_recipe)
  table.insert(new_things, battery_equipment)
  table.insert(new_things, battery_item)
end

function BatteryPack.process_vehicles()
  local new_things = {}
  for _,car in pairs(data.raw["car"]) do
    BatteryPack.process_vehicle(car, new_things)
  end
  for _,locomotive in pairs(data.raw["locomotive"]) do
    BatteryPack.process_vehicle(locomotive, new_things)
  end
  if next(new_things) then
    data:extend(new_things)
  end
end

BatteryPack.vehicle_blacklist = {
  -- these accept chemical fuel and have a non-zero fuel_inventory_size when we see them, but they're edited later
  ["et-electric-locomotive-mk1"] = true,
  ["et-electric-locomotive-mk2"] = true,
  ["et-electric-locomotive-mk3"] = true,
}

-- TODO intermediate hybrid version?
function BatteryPack.process_vehicle(old_vehicle, new_things)
  local old_item_name = BatteryPack.find_item_that_places_vehicle(old_vehicle)
  if not old_item_name then return end

  local old_item = data.raw["item-with-entity-data"][old_item_name] or data.raw["item"][old_item_name]
  if not old_item then return end

  local engines = BatteryPack.find_engines_for_item_name(old_item_name)

  local old_vehicle_name = old_vehicle.name

  if BatteryPack.vehicle_blacklist[old_vehicle_name] then return end

  local technology_list = BatteryPack.find_technologies_for_item(old_item_name)
  local start_enabled = true
  if next(technology_list) then
    start_enabled = false
  end

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
    enabled = start_enabled
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

  local burner

  if vehicle.burner then
    burner = vehicle.burner
  elseif vehicle.energy_source and vehicle.energy_source.type == "burner" then
    burner = vehicle.energy_source
  else
    return
  end

  -- TODO also read fuel_categories
  local fuel_category = burner.fuel_category

  if fuel_category and fuel_category ~= 'chemical' then return end

  local fuel_inventory_size = burner.fuel_inventory_size

  if fuel_inventory_size == 0 then return end

  burner.fuel_categories = nil
  burner.fuel_category = BatteryPack.fuel_category
  burner.burnt_inventory_size = fuel_inventory_size
  burner.smoke = nil

  local working_sound = vehicle.working_sound
  if working_sound then
    BatteryPack.patch_sound(working_sound, 'activate_sound')
    BatteryPack.patch_sound(working_sound, 'deactivate_sound')
    BatteryPack.patch_sound(working_sound, 'sound')
    if not (working_sound.sound or working_sound.activate_sound or working_sound.deactivate_sound) then
      vehicle.working_sound = nil
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
    { "entity-name." .. old_vehicle_name }
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

  -- TODO new technology that depends on one of technology_list and battey-equipment
  BatteryPack.add_recipe_to_technologies(electric_vehicle_name, technology_list)

  table.insert(new_things, vehicle)
  table.insert(new_things, item)
  table.insert(new_things, recipe)
end

BatteryPack.sound_replacement = {
  -- TODO ["__base__/sound/train-engine.ogg"] = "__BatteryPack__/sound/train-engine-no-rumble.ogg",
}

BatteryPack.sound_blacklist = {
  ["__base__/sound/car-engine-start.ogg"] = true,
  ["__base__/sound/car-engine-stop.ogg"] = true,
  ["__base__/sound/car-engine.ogg"] = true,
  ["__base__/sound/fight/car-no-fuel-1.ogg"] = true,
  ["__base__/sound/fight/tank-engine-start.ogg"] = true,
  ["__base__/sound/fight/tank-engine-stop.ogg"] = true,
  ["__base__/sound/fight/tank-engine.ogg"] = true,
  ["__base__/sound/fight/tank-no-fuel-1.ogg"] = true,
  ["__base__/sound/train-engine.ogg"] = true
}

function BatteryPack.patch_sound(sound, key)
  if not sound[key] then return end
  local filename = sound[key].filename
  if BatteryPack.sound_replacement[filename] then
    sound[key].filename = BatteryPack.sound_replacement[filename]
    return
  end
  if BatteryPack.sound_blacklist[filename] then
    sound[key] = nil
    return
  end
end

function BatteryPack.find_engines_for_item_name(item_name)
  local item_names_seen = {}
  local recipe_queue = {}

  local function register_recipes_for_item_name(item_name)
    if item_names_seen[item_name] then return end

    item_names_seen[item_name] = true

    local recipe_names = BatteryPack.find_recipes_for_thing(item_name)

    if not recipe_names then return end

    for _, recipe_name in ipairs(recipe_names) do
      table.insert(recipe_queue, recipe_name)
    end
  end

  register_recipes_for_item_name(item_name)

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
        name = ingredient[1]
        amount = ingredient[2]
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

      register_recipes_for_item_name(name)
      ::next_ingredient::
    end
  end

  return {}
end

function BatteryPack.find_technologies_for_item(item_name)
  -- if no technologies found, we are enabled from the start

  local original_recipes = BatteryPack.find_recipes_for_thing(item_name)
  local technology_list = {}

  if original_recipes then
    local technology_set = {}
    for _,recipe_name in ipairs(original_recipes) do
      local technologies = BatteryPack.find_technologies_for_recipe(recipe_name)
      if technologies then
        for _,technology_name in ipairs(technologies) do
          technology_set[technology_name] = 1
        end
      end
      local recipe = data.raw["recipe"][recipe_name]
      if recipe.enabled then
        -- at least one recipe is enabled from the start, so we should be too
        return {}
      end
    end
    for technology_name,_ in pairs(technology_set) do
      technology_list[#technology_list + 1] = technology_name
    end
    if not next(technology_list) then
      return {}
    end
  else
    -- TODO no recipe to build original item, yet it is otherwise valid, abort?
    return {}
  end
  ::stop_looking_for_technologies::

  return technology_list
end


do -- TODO reset this if we get called outside this module?
  local equipment_to_item_map = nil

  function build_item_to_equipment_map()
    equipment_to_item_map = {}

    for item_name, item in pairs(data.raw["item"]) do
      local equipment_name = item.placed_as_equipment_result
      if equipment_name then
        equipment_to_item_map[equipment_name] = item_name
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

  function build_item_to_vehicle_map()
    vehicle_to_item_map = {}

    for item_name, item in pairs(data.raw["item-with-entity-data"]) do
      local vehicle_name = item.place_result
      if vehicle_name then
        vehicle_to_item_map[vehicle_name] = item_name
      end
    end

    for item_name, item in pairs(data.raw["item"]) do
      local vehicle_name = item.place_result
      if vehicle_name then
        vehicle_to_item_map[vehicle_name] = item_name
      end
    end
  end

  function BatteryPack.find_item_that_places_vehicle(vehicle)
    if not vehicle_to_item_map then
      build_item_to_vehicle_map()
    end

    local vehicle_name = vehicle.name

    local candidate = vehicle_to_item_map[vehicle_name]

    if candidate then return candidate end

    return nil
  end
end

do
  local recipe_to_technology

  local function build_recipe_to_technology_map()
    recipe_to_technology = {}
    for technology_name,technology in pairs(data.raw["technology"]) do
      if not technology.effects then goto next_technology end
      for i,effect in ipairs(technology.effects) do
        if effect.type == "unlock-recipe" then
          if not recipe_to_technology[effect.recipe] then
            recipe_to_technology[effect.recipe] = {}
          end
          table.insert(recipe_to_technology[effect.recipe], technology_name)
        end
      end
      ::next_technology::
    end
  end

  function BatteryPack.find_technologies_for_recipe(recipe_name)
    if not recipe_to_technology then
      build_recipe_to_technology_map()
    end
    return recipe_to_technology[recipe_name]
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
        for i,result in ipairs(recipe.results) do
          if result.name then
            register_result(recipe_name, result.name)
          else
            register_result(recipe_name, result[1])
          end
        end
      end
      ::next_recipe::
    end
  end

  function BatteryPack.find_recipes_for_thing(thing_name)
    if not thing_to_recipe then
      build_thing_to_recipe_map()
    end
    return thing_to_recipe[thing_name]
  end
end

function BatteryPack.add_recipe_to_technologies(recipe_name, technology_list)
  if not technology_list then return end
  for i,technology in ipairs(technology_list) do
    table.insert(
      data.raw.technology[technology].effects,
      { type = "unlock-recipe", recipe = recipe_name }
    )
  end
end

-- https://wiki.factorio.com/Types/Energy
function BatteryPack.energy_to_joules(energy)
  if not energy then
    error(debug.traceback())
  end
  energy = energy:upper()
  energy = energy:gsub("W", "J")
  local e = energy:gsub("%u", "")
  if energy:find("YJ") then
    return e * 1000^8
  elseif energy:find("ZJ") then
    return e * 1000^7
  elseif energy:find("EJ") then
    return e * 1000^6
  elseif energy:find("PJ") then
    return e * 1000^5
  elseif energy:find("TJ") then
    return e * 1000^4
  elseif energy:find("GJ") then
    return e * 1000^3
  elseif energy:find("MJ") then
    return e * 1000^2
  elseif energy:find("KJ") then
    return e * 1000^1
  elseif energy:find("J") then
    return e * 1000^0
  else
    return e * 1000^0
  end
end

-- https://wiki.factorio.com/Types/Energy
function BatteryPack.joules_to_energy(energy, suffix)
  local prefix = {"", "k", "M", "G", "T", "P", "E", "Z", "Y"}
  local index = 1
  while energy > 1000 do
    energy = energy / 1000
    index = index + 1
  end
  return energy .. prefix[index] .. (suffix or "W")
end

function BatteryPack.add_icons(item, icons)
  if item.icon then
    item.icons = {
      { icon = item.icon }
    }
    item.icon = nil
  end
  for i,v in ipairs(icons) do
    item.icons[#item.icons + 1] = v
  end
end

BatteryPack.process_batteries()
BatteryPack.process_vehicles()
