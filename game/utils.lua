local M = {}

-- local neighbors = {{0, 0}, {-1, 0}, {-1, 1}, {0, 1}, {1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, -1}}
local neighbors = {{0, 0}, {1, 1}, {1, 0}, {1, -1}, {0, -1}}
local cell_size = 30
local entgrid = {} -- entity grid

-- In some rare cases with a lot of calculations and global 
-- function calls (like this code) it worth to pre-cache 
-- functions in local scope to avoid using global table.
-- More info: https://www.lua.org/gems/sample.pdf
-- it's not something you should do in regular code!
local f_sprite_play_flipbook = sprite.play_flipbook
local f_sprite_set_hflip = sprite.set_hflip
local f_msg_post = msg.post
local f_math_floor = math.floor
local f_table_remove = table.remove
local f_table_insert = table.insert

-- it's always better to calculate hashes only once
local DISABLE = hash("disable")
local ENABLE = hash("enable")

function M.get_z_position(entity)
    return -(entity.position_y/10000) + 0.5
end


function M.check_animation(entity)
    local x = entity.move_vector_x
    local y = entity.move_vector_y
    if x == 0 and y == 0 then
        if entity.anim_current ~= entity.anim_idle then
            entity.anim_current = entity.anim_idle
            f_sprite_play_flipbook(entity.sprite_url, entity.anim_idle)
        end
    else
        if entity.anim_current ~= entity.anim_run then
            entity.anim_current = entity.anim_run
            f_sprite_play_flipbook(entity.sprite_url, entity.anim_run)
        end
    end
end


function M.check_flip(entity)
    if entity.move_vector_x ~= 0 and entity.move_vector_x < 0 ~= entity.is_flip then
        entity.is_flip = (entity.move_vector_x < 0)
        f_sprite_set_hflip(entity.sprite_url, entity.is_flip)
    end
end


function M.set_sprite_enabled(entity, state)
    if entity.is_sprite_enabled ~= state then
        entity.is_sprite_enabled = state
        f_msg_post(entity.game_object, state and ENABLE or DISABLE)
    end
end


local function entgrid_key(x, y)
    return x * 1000 + y
end


local function check_entgrid_cell(key)
    entgrid[key] = entgrid[key] or {}
end


function M.entgrid_add(entity)
    local x = f_math_floor(entity.position_x / cell_size)
    local y = f_math_floor(entity.position_y / cell_size)
    local key = entgrid_key(x, y)
    check_entgrid_cell(key)
    f_table_insert(entgrid[key], entity)
end


function M.entgrid_update(entity)
    local x_prev = f_math_floor(entity.position_previous_x / cell_size)
    local y_prev = f_math_floor(entity.position_previous_y / cell_size)
    local x = f_math_floor(entity.position_x / cell_size)
    local y = f_math_floor(entity.position_y / cell_size)
    local key_prev = entgrid_key(x_prev, y_prev)
    local key = entgrid_key(x, y)

    if key_prev == key then
        return
    end

    for i = #entgrid[key_prev], 1, -1 do
        if entgrid[key_prev][i] == entity then
            f_table_remove(entgrid[key_prev], i)
        end
    end

    check_entgrid_cell(key)
    f_table_insert(entgrid[key], entity)
end


function M.entgrid_foreach(entity, callback)
    local x = f_math_floor(entity.position_x / cell_size)
    local y = f_math_floor(entity.position_y / cell_size)

    for i = 1, #neighbors do
        local n = neighbors[i]
        local key = entgrid_key(x + n[1], y + n[2])
        check_entgrid_cell(key)
        local entities = entgrid[key]
        for index = 1, #entities do
            if entity ~= entities[index] then
                callback(entity, entities[index])
            end
        end
    end
end


function M.entgrid_get_for(entity)
    local x = f_math_floor(entity.position_x / cell_size)
    local y = f_math_floor(entity.position_y / cell_size)
    local key = entgrid_key(x, y)
    check_entgrid_cell(key)
    return entgrid[key]
end


return M
