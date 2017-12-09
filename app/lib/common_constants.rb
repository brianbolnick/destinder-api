module CommonConstants
    SUBCLASSES = {
        '3225959819' => 'Nightstalker',
        '3635991036' => 'Gunslinger',
        '1334959255' => 'Arcstrider',
        '3887892656' => 'Voidwalker',
        '1751782730' => 'Stormcaller',
        '3481861797' => 'Dawnblade',
        '2958378809' => 'Striker',
        '3105935002' => 'Sunbreaker',
        '3382391785' => 'Sentinel',
        '2863201134' => 'Lost Light',
        '2934029575' => 'Lost Light',
        '1112909340' => 'Lost Light'
      }.freeze

    CHARACTER_CLASSES = { 0 => 'Titan', 1 => 'Hunter', 2 => 'Warlock' }.freeze

    GAME_MODES = {
      2 => 'story',
      3 => 'strike',
      4 => 'raid',
      5 => 'allPvP',
      6 => 'patrol',
      7 => 'allPvE',
      10 => 'control',
      12 => 'clash',
      16 => 'nightfall',
      17 => 'heroicNightfall',
      18 => 'allStrikes',
      19 => 'ironBanner',
      31 => 'supremacy',
      37 => 'survival',
      38 => 'countdown',
      39 => 'trialsofthenine'
    }.freeze

    ITEM_TYPES = {
      1498876634 => "primary_weapon_1",
      2465295065 => "primary_weapon_2",
      953998645 => "power_weapon",
      3448274439 => "helmet",
      3551918588 => "gauntlets",
      14239492 => "chest_armor",
      20886954 => "leg_armor",
      1585787867 => "class_item",
      # "4023194814" => "shell",
      # "284967655" => "ship",
      3284755031 => "subclass",
      # "4274335291" => "emblem",
      # "3054419239" => "emote", 
      1269569095 => "aura"
  }.freeze 
end