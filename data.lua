-- Modules

BatteryPack = {}

-- Constants

BatteryPack.MOD_NAME = "BatteryPack"
BatteryPack.PREFIX = BatteryPack.MOD_NAME .. "-"
BatteryPack.MOD_DIRECTORY = "__" .. BatteryPack.MOD_NAME .. "__/"
BatteryPack.GRAPHICS_DIRECTORY = BatteryPack.MOD_DIRECTORY .. "graphics/"

-- other values we're going to be using later

BatteryPack.CHARGER_POWER = 1000000 -- 1MW
BatteryPack.BATTERY_ROUND_TRIP_EFFICIENCY = 0.95 -- li-ion is around 95% efficient

BatteryPack.fuel_category = BatteryPack.PREFIX .. "category"
BatteryPack.charging_recipe_category = BatteryPack.PREFIX .. "charging"

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

data:extend({
  {
    type = "item",
    name = battery_holder_name,
    icon = BatteryPack.GRAPHICS_DIRECTORY .. "battery-holder.png",
    icon_size = 32,
    stack_size = 20,  -- battery-equipment stacks to 20
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
    icon = BatteryPack.GRAPHICS_DIRECTORY .. "battery-contact.png",
    icon_size = 32,
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
    icon = BatteryPack.GRAPHICS_DIRECTORY .. "battery-holder-frame.png",
    icon_size = 32,
    stack_size = 20, -- battery-equipment stacks to 20
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


-- battery charger

BatteryPack.building_template = {
  type = nil,
  name = nil,
  collision_box = {
    {
      -0.9,
      -0.9
    },
    {
      0.9,
      0.9
    }
  },
  corpse = "medium-remnants",
  dying_explosion = "medium-explosion",
  drawing_box = {
    {
      -1,
      -1.5,
    },
    {
      1,
      1
    }
  },
  flags = {
    "placeable-neutral",
    "player-creation"
  },
  icon = "__base__/graphics/icons/accumulator.png",
  icon_size = 32,
  max_health = 150,
  minable = {
    mining_time = 0.1,
    result = nil
  },
  selection_box = {
    {
      -1,
      -1
    },
    {
      1,
      1
    }
  },
  vehicle_impact_sound = {
    filename = "__base__/sound/car-metal-impact.ogg",
    volume = 0.65
  },
  working_sound = {
    idle_sound = {
      filename = "__base__/sound/accumulator-idle.ogg",
      volume = 0.4
    },
    max_sounds_per_type = 5,
    sound = {
      filename = "__base__/sound/accumulator-working.ogg",
      volume = 1
    }
  }
}

local accumulator = data.raw["accumulator"]["accumulator"]

local charger_name = BatteryPack.PREFIX .. "charger"
local discharger_name = BatteryPack.PREFIX .. "discharger"

local charger = table.deepcopy(BatteryPack.building_template)
local discharger = table.deepcopy(BatteryPack.building_template)

charger.type = "furnace"
charger.name = charger_name
charger.minable.result = charger_name
charger.energy_usage = "200MW"
charger.crafting_speed = 1
charger.crafting_categories = { BatteryPack.charging_recipe_category }
charger.energy_source = {
  type = "electric",
  usage_priority = "tertiary",
  output_flow_limit = "0.001W",
  drain = "0W"
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
  localised_name = charger.localised_name,
  localised_description = charger.localised_description,
  icon = "__base__/graphics/icons/accumulator.png",
  icon_size = 32,
  place_result = charger_name,
  stack_size = 50,
  subgroup = "energy",
  order = "e[accumulator]-a[charger]"
}

local charger_recipe = {
  type = "recipe",
  name = charger_name,
  icon = "__base__/graphics/icons/accumulator.png",
  icon_size = 32,
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


discharger.type = "generator"
discharger.name = discharger_name
discharger.minable.result = discharger_name
discharger.energy_source = {
  type = "electric",
  usage_priority = "tertiary",
  input_flow_limit = "0.001W"
}
discharger.burner = {
  type = "burner",
  emissions_per_second_per_watt = 0,
  fuel_inventory_size = 1,
  burnt_inventory_size = 1,
  effectivity = 1,
  fuel_category = BatteryPack.fuel_category,
}
discharger.horizontal_animation = accumulator.picture
discharger.vertical_animation = accumulator.picture
discharger.effectivity = 1
discharger.max_power_output = "200MW"

local discharger_equipment = {
  type = "generator-equipment",
  name = discharger_name,
  sprite = {
    filename = "__base__/graphics/icons/accumulator.png",
    height = 32,
    width = 32,
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
  icon = "__base__/graphics/icons/accumulator.png",
  icon_size = 32,
  place_result = discharger_name,
  placed_as_equipment_result = discharger_name,
  stack_size = 50,
  subgroup = "energy",
  order = "e[accumulator]-a[discharger]"
}

local discharger_recipe = {
  type = "recipe",
  name = discharger_name,
  icon = "__base__/graphics/icons/accumulator.png",
  icon_size = 32,
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

-- recipe unlock

local battery_equipment_technology = data.raw["technology"]["battery-equipment"]
local battery_equipment_technology_effects = battery_equipment_technology.effects

table.insert(battery_equipment_technology_effects, {
  type = "unlock-recipe",
  recipe = battery_holder_contact_name
})

table.insert(battery_equipment_technology_effects, {
  type = "unlock-recipe",
  recipe = battery_holder_frame_name
})

table.insert(battery_equipment_technology_effects, {
  type = "unlock-recipe",
  recipe = battery_holder_name
})

table.insert(battery_equipment_technology_effects, {
  type = "unlock-recipe",
  recipe = charger_name
})

table.insert(battery_equipment_technology_effects, {
  type = "unlock-recipe",
  recipe = discharger_name
})
