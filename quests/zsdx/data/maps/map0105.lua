-- Dungeon 9 1F

puzzle_b_next = nil -- index of the next correct switch (nil = error or not started)
puzzle_b_nb_activated = 0

function event_map_started(destination_point_name)

  -- hidden Gibdo and chest
  sol.map.enemy_set_group_enabled("hidden_enemy", false)
  if not sol.game.savegame_get_boolean(800) then
    sol.map.chest_set_enabled("hidden_enemy_chest", false)
  end

  -- puzzle A
  if sol.game.savegame_get_boolean(802) then
    -- already solved
    sol.map.tile_set_group_enabled("puzzle_a_switch_red", false)
    sol.map.switch_set_group_enabled("puzzle_a_switch", false)
  else
    -- not solved yet
    sol.map.chest_set_enabled("puzzle_a_chest", false)
  end
  sol.map.tile_set_group_enabled("puzzle_a_switch_green", false)

  -- puzzle B
  if destination_point_name == "from_b1_w" then
    sol.map.door_set_open("puzzle_b_door", true)
    sol.map.switch_set_activated("puzzle_b_door_switch", true)
  end
end

function event_map_opening_transition_finished(destination_point_name)

  -- show the welcome message
  if destination_point_name == "from_outside" then
    sol.map.dialog_start("dungeon_9.welcome")
  end
end

function event_update()

  -- hidden enemies
  local x, y = sol.map.hero_get_position()
  if x > 1056 and x < 1200 and y > 1888 and y < 1968
      and not sol.map.chest_is_enabled("hidden_enemy_chest")
      and not sol.map.enemy_is_group_dead("hidden_enemy")
      and not sol.map.enemy_is_enabled("hidden_enemy_1") then

    sol.main.play_sound("cane")
    sol.map.enemy_set_enabled("hidden_enemy_1", true)
    sol.map.enemy_set_enabled("hidden_enemy_2", true)
  end
end

function event_enemy_dead(enemy_name)

  -- hidden enemies
  if enemy_name:find("^hidden_enemy")
      and sol.map.enemy_is_group_dead("hidden_enemy")
      and not sol.map.chest_is_enabled("hidden_enemy_chest") then
    sol.map.camera_move(1128, 2040, 250, function()
      sol.main.play_sound("chest_appears")
      sol.map.chest_set_enabled("hidden_enemy_chest", true)
    end)
  end
end

function event_switch_activated(switch_name)

  -- door to puzzle B
  if switch_name == "puzzle_b_door_switch"
      and not sol.map.door_is_open("puzzle_b_door") then
    sol.map.camera_move(808, 1544, 250, function()
      sol.main.play_sound("secret")
      sol.map.door_open("puzzle_b_door")
      sol.map.switch_set_activated("puzzle_b_door_switch", true)
    end)

  -- puzzle B: the switches have to be activated clockwise
  elseif switch_name:find("^puzzle_b_switch") then

    local index = tonumber(switch_name:match("^puzzle_b_switch_([1-4])$"))
    if puzzle_b_nb_activated == 0 then
      -- first one
      puzzle_b_next = index
    end
  
    if index == puzzle_b_next then
      -- okay so far
      puzzle_b_next = puzzle_b_next % 4 + 1
    else
      -- error
      puzzle_b_next = nil
    end
    puzzle_b_nb_activated = puzzle_b_nb_activated + 1

    if puzzle_b_nb_activated == 4 then
      -- the 4 switches are on, was there an error?
      if puzzle_b_next == nil then
	-- error
	sol.main.play_sound("wrong")
	for i = 1, 4 do
	  sol.map.switch_set_activated("puzzle_b_switch_" .. i, false)
	end
	puzzle_b_nb_activated = 0
	sol.map.switch_set_locked(switch_name, true)
	-- to avoid the switch to be activated again immediately
      else
	-- correct
	sol.main.play_sound("secret")
	sol.map.door_open("puzzle_b_door")
        sol.map.switch_set_activated("puzzle_b_door_switch", true)
      end
    end
  
  -- puzzle A: each switch changes its neighboors in the 4 main directions
  elseif switch_name:find("^puzzle_a_switch") then
    sol.main.play_sound("switch")
    local to_change = { {2,4}, {1,3,5}, {2,6}, {1,5}, {2,4,6}, {3,5} }
    local index = tonumber(switch_name:match("^puzzle_a_switch_([1-6])$"))
    if index then

      -- invert the neighboors
      for i, v in ipairs(to_change[index]) do
	local on = sol.map.tile_is_enabled("puzzle_a_switch_red_" .. v)
	sol.map.tile_set_enabled("puzzle_a_switch_green_" .. v, on)
	sol.map.tile_set_enabled("puzzle_a_switch_red_" .. v, not on)
      end
      
      -- check the success
      local success = true
      for i = 1, 6 do
	if sol.map.tile_is_enabled("puzzle_a_switch_red_" .. i) then
	  success = false
	  break
	end
      end
      if success then
	sol.main.play_sound("secret")
	sol.map.tile_set_group_enabled("puzzle_a_switch", false)
	sol.map.switch_set_group_enabled("puzzle_a_switch", false)
	sol.map.camera_move(896, 1896, 250, function()
	  sol.main.play_sound("chest_appears")
	  sol.map.chest_set_enabled("puzzle_a_chest", true)
	  sol.game.savegame_set_boolean(802, true)
	end)
      end
    end
  end
end

function event_switch_left(switch_name)

  if switch_name:find("^puzzle_b_switch") then
    if puzzle_b_nb_activated == 0 then
      sol.map.switch_set_locked(switch_name, false)
    end
  end
end

function event_hero_on_sensor(sensor_name)

  if sensor_name:find("^close_puzzle_b_door_sensor") then

    if not sol.map.switch_is_activated("puzzle_b_switch_1")
        and sol.map.door_is_open("puzzle_b_door") then
      sol.map.door_close("puzzle_b_door")
      sol.map.switch_set_activated("puzzle_b_door_switch", false)
    end
  end
end
