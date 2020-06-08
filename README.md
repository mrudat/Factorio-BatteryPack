A combination of [Modular Charge Packs](https://mods.factorio.com/mod/ModularChargePacks), [Batteries Not Included](https://mods.factorio.com/mod/BatteriesNotIncluded) and [Power Cubes](https://mods.factorio.com/mod/PowerCubes).

It allows you to charge personal batteries from your factory, and use that stored power in your equipment grid, in specially modified vehicles, and also to power your factory.

## "Support" for (turning Battery Pack off for) other mods

To stop Battery Pack from creating Battery-Powered vehicles derived from a mod-added vehicle, you can add a key to `BatteryPack.vehicle_blacklist`, for example:

    BatteryPack.vehicle_blacklist['my-special-vehicle'] = true

To stop Battery Pack from creating charged versions of battery equipment, you can add a key to `BatteryPack.equipment_blacklist` or `BatteryPack.item_blacklist`, for example:

    BatteryPack.equipment_blacklist['not-actually-a-battery'] = true
    BatteryPack.item_blacklist['pretends-to-be-a-battery'] = true

To get Battery Pack to treat a battery as a primary battery (add a fuel value, don't return a discharged battery), add a key to `BatteryPack.primary_batteries`, for example:

    BatteryPack.primary_batteries['a-primary-battery'] = true
