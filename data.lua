local ORNodes = require('__OR-Nodes__/library.lua').init()
local rusty_icons = require('__rusty-locale__/icons')

local icons_of = rusty_icons.of

-- Modules

BatteryPack = {}

-- TODO better graphics.

-- Constants

BatteryPack.MOD_NAME = "BatteryPack"
BatteryPack.PREFIX = BatteryPack.MOD_NAME .. "-"
BatteryPack.MOD_DIRECTORY = "__" .. BatteryPack.MOD_NAME .. "__/"
BatteryPack.GRAPHICS_DIRECTORY = BatteryPack.MOD_DIRECTORY .. "graphics/"

-- other values we're going to be using later

BatteryPack.BATTERY_ROUND_TRIP_EFFICIENCY = 0.95 -- li-ion is around 95% efficient

BatteryPack.fuel_category = BatteryPack.PREFIX .. "category"
BatteryPack.charging_recipe_category = BatteryPack.PREFIX .. "charging"

BatteryPack.discharged_icons = {
  -- ["battery_equipment_name"] = { icons }
}

BatteryPack.discharged_overlays = {
  ["2x1"] = {
      {
      icon = BatteryPack.GRAPHICS_DIRECTORY .. "dark-overlay-2x1.png",
      tint = { r=0, g=0, b=0, a=0.6 },
      icon_size = 32
    }
  },
  ["1x1"] = {
      {
      icon = BatteryPack.GRAPHICS_DIRECTORY .. "dark-overlay-1x1.png",
      tint = { r=0, g=0, b=0, a=0.6 },
      icon_size = 32
    }
  },
  ["battery-equipment"] = {
      {
      icon = BatteryPack.GRAPHICS_DIRECTORY .. "battery-equipment.png",
      tint = { r=0, g=0, b=0, a=1 },
      icon_size = 64, icon_mipmaps = 4
    }
  },
  ["battery-mk2-equipment"] = {
      {
      icon = BatteryPack.GRAPHICS_DIRECTORY .. "battery-mk2-equipment.png",
      tint = { r=0, g=0, b=0, a=1 },
      icon_size = 64, icon_mipmaps = 4
    }
  },
  ["default"] = {
      {
      icon = BatteryPack.GRAPHICS_DIRECTORY .. "dark-overlay.png",
      tint = { r=0, g=0, b=0, a=1 },
      icon_size = 32
    }
  }
}

BatteryPack.equipment_blacklist = {
  -- Not actually a battery.
  ["heli-remote-equipment"] = true
}

BatteryPack.item_blacklist = {}

BatteryPack.primary_batteries = {
  -- SchallPrimaryBattery
  ["primary-battery-equipment-alkaline"] = true,
  ["primary-battery-equipment-dry"] = true
}

BatteryPack.vehicle_blacklist = {
  -- these accept chemical fuel and have a non-zero fuel_inventory_size when we see them, but they're edited later
  ["et-electric-locomotive-mk1"] = true,
  ["et-electric-locomotive-mk2"] = true,
  ["et-electric-locomotive-mk3"] = true,
  -- These are used internally by Cargo Ships.
  ["cargo_ship_engine"] = true,
  ["boat_engine"] = true,
  -- These need runtime support
  ["vehicle-miner"] = true,
  ["vehicle-miner-mk2"] = true,
  ["vehicle-miner-mk3"] = true,
  ["vehicle-miner-mk4"] = true,
  ["vehicle-miner-mk5"] = true,
}

BatteryPack.sound_replacement = {
  ["__base__/sound/train-engine.ogg"] = {
    filename = "__base__/sound/substation.ogg",
    volume = 0.5
  },
  ["__base__/sound/car-engine.ogg"] = {
    filename = "__base__/sound/substation.ogg",
    volume = 0.5
  },
  ["__base__/sound/fight/tank-engine.ogg"] = {
    filename = "__base__/sound/substation.ogg",
    volume = 0.5
  },
}

BatteryPack.sound_blacklist = {
  ["__base__/sound/car-engine-start.ogg"] = true,
  ["__base__/sound/car-engine-stop.ogg"] = true,
  ["__base__/sound/fight/car-no-fuel-1.ogg"] = true,
  ["__base__/sound/fight/tank-engine-start.ogg"] = true,
  ["__base__/sound/fight/tank-engine-stop.ogg"] = true,
  ["__base__/sound/fight/tank-no-fuel-1.ogg"] = true
}

local intermediate_recipes = {}

data:extend({
  {
    type = "recipe-category",
    name = BatteryPack.charging_recipe_category
  },
  {
    type = "fuel-category",
    name = BatteryPack.fuel_category
  },
})

-- battery holder

local battery_holder_name = BatteryPack.PREFIX .. "battery-holder"
local battery_holder_contact_name = BatteryPack.PREFIX .. "battery-holder-contact"
local battery_holder_frame_name = BatteryPack.PREFIX .. "battery-holder-frame"

table.insert(intermediate_recipes,battery_holder_name)
table.insert(intermediate_recipes,battery_holder_contact_name)
table.insert(intermediate_recipes,battery_holder_frame_name)

--local battery_equipment = data.raw['battery-equipment']['battery-equipment']
--BatteryPack.CHARGER_POWER = util.parse_energy(battery_equipment.energy_source.input_flow_limit)
BatteryPack.CHARGER_POWER = 200000000 -- 200MW


local battery_equipment_stack_size = data.raw.item['battery-equipment'].stack_size

data:extend({
  {
    type = "item",
    name = battery_holder_name,
    icon = BatteryPack.GRAPHICS_DIRECTORY .. "icons/battery-holder.png",
    icon_size = 64,
    stack_size = battery_equipment_stack_size,
    subgroup = "intermediate-product",
    order = "g[battery-holder]"
  },
  {
    type = "recipe",
    name = battery_holder_name,
    ingredients = {
      {
        type = "item",
        name = battery_holder_frame_name,
        amount = 1,
      },
      {
        type = "item",
        name = battery_holder_contact_name,
        amount = 2,
      },
      {
        type = "item",
        name = "copper-cable", -- 5Kg ea.
        amount = 2,
      }
    },
    results = {
      {
        type = "item",
        name = battery_holder_name,
        amount = 1
      }
    },
    energy_required = 0.5,
    enabled = false,
    show_amount_in_title = true,
  },

  {
    type = "item",
    name = battery_holder_contact_name,
    icon = BatteryPack.GRAPHICS_DIRECTORY .. "icons/battery-contact.png",
    icon_size = 64,
    stack_size = 200, -- small fiddly thing.
    subgroup = "intermediate-product",
    order = "g[battery-holder-contact]"
  },
  {
    type = "recipe",
    name = battery_holder_contact_name,
    ingredients = {
      {
        type = "item",
        name = "steel-plate", -- 10Kg
        amount = 1,
      }
    },
    results = {
      {
        type = "item",
        name = battery_holder_contact_name, -- 100g
        amount = 100
      }
    },
    energy_required = 50,
    enabled = false,
    show_amount_in_title = true,
  },

  {
    type = "item",
    name = battery_holder_frame_name,
    icon = BatteryPack.GRAPHICS_DIRECTORY .. "icons/battery-holder-frame.png",
    icon_size = 64,
    stack_size = battery_equipment_stack_size,
    subgroup = "intermediate-product",
    order = "g[battery-holder-frame]"
  },
  {
    type = "recipe",
    name = battery_holder_frame_name,
    ingredients = {
      {
        type = "item",
        name = "plastic-bar", -- 10Kg
        amount = 1,
      },
    },
    results = {
      {
        type = "item",
        name = battery_holder_frame_name, -- 2Kg
        amount = 5
      }
    },
    energy_required = 2.5,
    enabled = false,
    show_amount_in_title = true,
  }

})


local accumulator = data.raw["accumulator"]["accumulator"]
local accumulator_icons = icons_of(accumulator)


local building_template = table.deepcopy(accumulator)

local remove_properties = {
  "type",
  "name",
  "charge_animation",
  "charge_cooldown",
  "charge_light",
  "discharge_animation",
  "discharge_cooldown",
  "discharge_light",
  "circuit_wire_connection_point",
  "circuit_wire_connector_sprites",
  "circuit_wire_max_distance",
  "default_output_signal"
}

for _, key in ipairs(remove_properties) do
  building_template[key] = nil
end

local charger_name = BatteryPack.PREFIX .. "charger"
local discharger_name = BatteryPack.PREFIX .. "discharger"

local charger = table.deepcopy(building_template)
local discharger = table.deepcopy(building_template)

charger.type = "furnace"
charger.name = charger_name
charger.minable.result = charger_name
charger.energy_usage = BatteryPack.CHARGER_POWER .. 'W'
charger.crafting_speed = 1
charger.crafting_categories = { BatteryPack.charging_recipe_category }
charger.energy_source = {
  type = "electric",
  usage_priority = "tertiary",
  output_flow_limit = '0W',
  input_flow_limit = BatteryPack.CHARGER_POWER .. 'W',
  drain = '0W'
}
charger.result_inventory_size = 1
charger.source_inventory_size = 1
charger.animation = accumulator.picture
charger.working_visualisations = {
  {
    animation = accumulator.charge_animation,
    light = accumulator.charge_light
  }
}



local charger_item = {
  type = "item",
  name = charger_name,
  icons = accumulator_icons,
  place_result = charger_name,
  stack_size = 50,
  subgroup = "energy",
  order = "e[accumulator]-a[charger]"
}

local charger_recipe = {
  type = "recipe",
  name = charger_name,
  icons = accumulator_icons,
  ingredients = {
    {
      type = "item",
      name = "iron-plate",
      amount = 2
    },
    {
      type = "item",
      name = "electronic-circuit",
      amount = 5
    },
    {
      type = "item",
      name = battery_holder_name,
      amount = 1
    }
  },
  results = {
    {
      type = "item",
      name = charger_name,
      amount = 1
    }
  },
  energy_required = 0.5,
  enabled = false
}

discharger.type = "burner-generator"
discharger.name = discharger_name
discharger.minable.result = discharger_name
discharger.energy_source = {
  type = "electric",
  usage_priority = "tertiary",
  input_flow_limit = '0W'
}
discharger.burner = {
  type = "burner",
  emissions_per_minute = 0,
  fuel_inventory_size = 1,
  burnt_inventory_size = 1,
  effectivity = 1,
  fuel_category = BatteryPack.fuel_category,
}
discharger.animation = accumulator.discharge_animation
discharger.idle_animation = accumulator_picture({ r=1, g=1, b=1, a=1 } , 24)
discharger.effectivity = 1
discharger.max_power_output = BatteryPack.CHARGER_POWER .. 'W'

local accumulator_icon = accumulator_icons[1]

local discharger_equipment = {
  type = "generator-equipment",
  name = discharger_name,
  sprite = {
    filename = accumulator_icon.icon,
    height = accumulator_icon.icon_size or 32,
    width = accumulator_icon.icon_size or 32,
    priority = "medium"
  },
  shape = {
    type = "full",
    width = 2,
    height = 2
  },
  burner = {
    emissions_per_second_per_watt = 0,
    fuel_inventory_size = 1, -- enough for 2 seconds of operation!
    burnt_inventory_size = 1,
    effectivity = 1,
    fuel_category = BatteryPack.fuel_category,
  },
  energy_source = {
    type = "burner",
    usage_priority = "secondary-output"
  },
  power = "200MW",
  categories = { "armor" }
}

local discharger_item = {
  type = "item",
  name = discharger_name,
  localised_name = discharger.localised_name,
  localised_description = discharger.localised_description,
  icons = accumulator_icons,
  place_result = discharger_name,
  placed_as_equipment_result = discharger_name,
  stack_size = 50,
  subgroup = "energy",
  order = "e[accumulator]-a[discharger]"
}

local discharger_recipe = {
  type = "recipe",
  name = discharger_name,
  icons = accumulator_icons,
  ingredients = {
    {
      type = "item",
      name = "iron-plate",
      amount = 2
    },
    {
      type = "item",
      name = "electronic-circuit",
      amount = 5
    },
    {
      type = "item",
      name = battery_holder_name,
      amount = 1
    }
  },
  results = {
    {
      type = "item",
      name = discharger_name,
      amount = 1
    }
  },
  energy_required = 0.5,
  enabled = false
}

data:extend{
  charger,
  charger_item,
  charger_recipe,
  discharger,
  discharger_item,
  discharger_equipment,
  discharger_recipe
}

-- productivity modules

for _, module in pairs(data.raw["module"]) do
  local module_effect = module.effect
  local productivity_effect = module_effect["productivity"]
  if not productivity_effect then goto next_module end
  local limitation = module.limitation
  if not limitation then goto next_module end
  for _,recipe_name in ipairs(intermediate_recipes) do
    table.insert(limitation, recipe_name)
  end
  ::next_module::
end

local plastic_bar_technology = ORNodes.depend_on_item("plastic-bar")

local battery_holder_technology_name = BatteryPack.PREFIX .. 'battery-holder'
BatteryPack.battery_charger_technology = BatteryPack.PREFIX .. 'battery-charger'
BatteryPack.battery_power_plant = BatteryPack.PREFIX .. 'battery-power-plant'
BatteryPack.battery_charging_technology = BatteryPack.PREFIX .. 'battery-charging'
BatteryPack.power_inverter_technology = BatteryPack.PREFIX .. 'power-inverter'
BatteryPack.electric_vehicle_technology = BatteryPack.PREFIX .. 'electric-vehicles'

local accumulator_technology = data.raw.technology["electric-energy-accumulators"]

do
  local accumulator_normal = accumulator_technology.normal
  local accumulator_expensive = accumulator_technology.expensive

  if accumulator_normal or accumulator_expensive then
    if accumulator_normal then
      accumulator_normal.unit.count = accumulator_normal.unit.count / 3
    end
    if accumulator_expensive then
      accumulator_expensive.unit.count = accumulator_expensive.unit.count / 3
    end
  else
    accumulator_technology.unit.count = accumulator_technology.unit.count / 3
  end
end

local accumulator_technology_icons = icons_of(accumulator_technology, true)

local battery_charging_technology = table.deepcopy(accumulator_technology)

battery_charging_technology.name = BatteryPack.battery_charging_technology
battery_charging_technology.effects = nil
battery_charging_technology.localised_name = nil

local power_inverter_technology = table.deepcopy(accumulator_technology)
power_inverter_technology.name = BatteryPack.power_inverter_technology
power_inverter_technology.effects = nil
power_inverter_technology.localised_name = nil

accumulator_technology.prerequisites = {
  BatteryPack.battery_charging_technology,
  BatteryPack.power_inverter_technology
}
data:extend{power_inverter_technology}
data:extend{battery_charging_technology}
data:extend{accumulator_technology}

data:extend{
  {
    type = "technology",
    name = battery_holder_technology_name,
    icons = {
      {
        icon = BatteryPack.GRAPHICS_DIRECTORY .. 'technology/battery-holder.png',
        icon_size = 128
      }
    },
    unit = {
      count = 5,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
      },
      time = 15
    },
    effects = {
      {
        type = "unlock-recipe",
        recipe = battery_holder_contact_name
      },
      {
        type = "unlock-recipe",
        recipe = battery_holder_frame_name
      },
      {
        type = "unlock-recipe",
        recipe = battery_holder_name
      }
    },
    prerequisites = {
      "battery",
      plastic_bar_technology[1]
    }
  },
  {
    type = "technology",
    name = BatteryPack.battery_charger_technology,
    icons = accumulator_technology_icons,
    unit = {
      count = 5,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
      },
      time = 15
    },
    effects = {
      {
        type = "unlock-recipe",
        recipe = charger_name
      }
    },
    prerequisites = {
      battery_holder_technology_name,
      BatteryPack.battery_charging_technology,
      -- depends on first unlocked battery equipment (added in data-update)
    }
  },
  {
    type = "technology",
    name = BatteryPack.battery_power_plant,
    icons = accumulator_technology_icons,
    unit = {
      count = 5,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
      },
      time = 15
    },
    effects = {
      {
        type = "unlock-recipe",
        recipe = discharger_name
      }
    },
    prerequisites = {
      battery_holder_technology_name,
      BatteryPack.power_inverter_technology,
      -- depends on first unlocked battery equipment (added in data-update)
    }
  },
  {
    type = "technology",
    name = BatteryPack.electric_vehicle_technology,
    icons = {
      {
        --icon = BatteryPack.GRAPHICS_DIRECTORY .. 'technology/electric_vehicles.png',
        icon = BatteryPack.GRAPHICS_DIRECTORY .. 'technology/battery-holder.png',
        icon_size = 128
      }
    },
    unit = {
      count = 5,
      ingredients = {
        {"automation-science-pack", 1},
        {"logistic-science-pack", 1},
      },
      time = 15
    },
    prerequisites = {
      battery_holder_technology_name,
      BatteryPack.power_inverter_technology,
      "electric-engine",
      -- depends on first unlocked vehicle (added in data-update)
    }
  }
}
