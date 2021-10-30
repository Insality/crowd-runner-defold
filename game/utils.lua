local M = {}

-- local neighbors = {{0, 0}, {-1, 0}, {-1, 1}, {0, 1}, {1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, -1}}
local neighbors = {{0, 0}, {1, 1}, {1, 0}, {1, -1}, {0, -1}}
local cell_size = 22
local octotree = {}


function M.update_z_position(entity)
    local position = entity.position
    position.z = -(position.y/10000) + 0.5
end


function M.check_animation(entity)
    local v = entity.move_vector
    if math.sqrt(v.x * v.x + v.y * v.y) == 0 then
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
    if entity.move_vector.x ~= 0 and entity.move_vector.x < 0 ~= entity.is_flip then
        entity.is_flip = (entity.move_vector.x < 0)
        sprite.set_hflip(entity.sprite_url, entity.is_flip)
    end
end


local function octotree_key(x, y)
    return x * 1000 + y
end


local function check_octotree_cell(key)
    octotree[key] = octotree[key] or {}
end


function M.octotree_add(entity)
    local x = math.floor(entity.position.x / cell_size)
    local y = math.floor(entity.position.y / cell_size)
    local key = octotree_key(x, y)
    check_octotree_cell(key)
    table.insert(octotree[key], entity)
end


function M.octotree_update(entity)
    local x_prev = math.floor(entity.position_previous.x / cell_size)
    local y_prev = math.floor(entity.position_previous.y / cell_size)
    local x = math.floor(entity.position.x / cell_size)
    local y = math.floor(entity.position.y / cell_size)
    local key_prev = octotree_key(x_prev, y_prev)
    local key = octotree_key(x, y)

    if key_prev == key then
        return
    end

    for i = #octotree[key_prev], 1, -1 do
        if octotree[key_prev][i] == entity then
            table.remove(octotree[key_prev], i)
        end
    end

    check_octotree_cell(key)
    table.insert(octotree[key], entity)
end


function M.octotree_foreach(entity, callback)
    local x = math.floor(entity.position.x / cell_size)
    local y = math.floor(entity.position.y / cell_size)

    for i = 1, #neighbors do
        local n = neighbors[i]
        local key = octotree_key(x + n[1], y + n[2])
        check_octotree_cell(key)
        local entities = octotree[key]
        for index = 1, #entities do
            if entity ~= entities[index] then
                callback(entities[index])
            end
        end
    end
end


function M.octotree_get_for(entity)
    local x = math.floor(entity.position.x / cell_size)
    local y = math.floor(entity.position.y / cell_size)
    local key = octotree_key(x, y)
    check_octotree_cell(key)
    return octotree[key]
end


return M
