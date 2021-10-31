local M = {}

-- local neighbors = {{0, 0}, {-1, 0}, {-1, 1}, {0, 1}, {1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, -1}}
local neighbors = {{0, 0}, {1, 1}, {1, 0}, {1, -1}, {0, -1}}
local cell_size = 22
local entgrid = {} -- entity grid


function M.get_z_position(entity)
    return -(entity.position_y/10000) + 0.5
end


function M.check_animation(entity)
    local x = entity.move_vector_x
    local y = entity.move_vector_y
    if math.sqrt(x * x + y * y) == 0 then
        if entity.anim_current ~= entity.anim_idle then
            entity.anim_current = entity.anim_idle
            sprite.play_flipbook(entity.sprite_url, entity.anim_idle)
        end
    else
        if entity.anim_current ~= entity.anim_run then
            entity.anim_current = entity.anim_run
            sprite.play_flipbook(entity.sprite_url, entity.anim_run)
        end
    end
end


function M.check_flip(entity)
    if entity.move_vector_x ~= 0 and entity.move_vector_x < 0 ~= entity.is_flip then
        entity.is_flip = (entity.move_vector_x < 0)
        sprite.set_hflip(entity.sprite_url, entity.is_flip)
    end
end


local function entgrid_key(x, y)
    return x * 1000 + y
end


local function check_entgrid_cell(key)
    entgrid[key] = entgrid[key] or {}
end


function M.entgrid_add(entity)
    local x = math.floor(entity.position_x / cell_size)
    local y = math.floor(entity.position_y / cell_size)
    local key = entgrid_key(x, y)
    check_entgrid_cell(key)
    table.insert(entgrid[key], entity)
end


function M.entgrid_update(entity)
    local x_prev = math.floor(entity.position_previous_x / cell_size)
    local y_prev = math.floor(entity.position_previous_y / cell_size)
    local x = math.floor(entity.position_x / cell_size)
    local y = math.floor(entity.position_y / cell_size)
    local key_prev = entgrid_key(x_prev, y_prev)
    local key = entgrid_key(x, y)

    if key_prev == key then
        return
    end

    for i = #entgrid[key_prev], 1, -1 do
        if entgrid[key_prev][i] == entity then
            table.remove(entgrid[key_prev], i)
        end
    end

    check_entgrid_cell(key)
    table.insert(entgrid[key], entity)
end


function M.entgrid_foreach(entity, callback)
    local x = math.floor(entity.position_x / cell_size)
    local y = math.floor(entity.position_y / cell_size)

    for i = 1, #neighbors do
        local n = neighbors[i]
        local key = entgrid_key(x + n[1], y + n[2])
        check_entgrid_cell(key)
        local entities = entgrid[key]
        for index = 1, #entities do
            if entity ~= entities[index] then
                callback(entities[index])
            end
        end
    end
end


function M.entgrid_get_for(entity)
    local x = math.floor(entity.position_x / cell_size)
    local y = math.floor(entity.position_y / cell_size)
    local key = entgrid_key(x, y)
    check_entgrid_cell(key)
    return entgrid[key]
end


return M
