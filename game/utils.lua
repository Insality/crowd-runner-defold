local M = {}

local neighbors = {{0, 0}, {-1, 0}, {-1, 1}, {0, 1}, {1, 1}, {1, 0}, {1, -1}, {0, -1}, {-1, -1}}
local cell_size = 21
local octotree = {}


function M.update_z_position(entity)
    local position = entity.position
    position.z = -(position.y/10000) + 0.5
end


function M.check_animation(entity)
    if vmath.length(entity.move_vector) == 0 then
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


local function check_octotree_cell(x, y)
    octotree[x] = octotree[x] or {}
    octotree[x][y] = octotree[x][y] or {}
end


function M.octotree_add(entity)
    local x = math.floor(entity.position.x / cell_size)
    local y = math.floor(entity.position.y / cell_size)
    for index = 1, #neighbors do
        local n = neighbors[index]
        check_octotree_cell(x + n[1], y + n[2])
        table.insert(octotree[x + n[1]][y + n[2]], entity)
    end
end


function M.octotree_update(entity)
    local x_prev = math.floor(entity.position_previous.x / cell_size)
    local y_prev = math.floor(entity.position_previous.y / cell_size)
    local x = math.floor(entity.position.x / cell_size)
    local y = math.floor(entity.position.y / cell_size)

    if x_prev == x and y_prev == y then
        return
    end

    for index = 1, #neighbors do
        local n = neighbors[index]
        for i = #octotree[x_prev + n[1]][y_prev + n[2]], 1, -1 do
            if octotree[x_prev + n[1]][y_prev + n[2]][i] == entity then
                table.remove(octotree[x_prev + n[1]][y_prev + n[2]], i)
            end
        end
    end

    for index = 1, #neighbors do
        local n = neighbors[index]
        check_octotree_cell(x + n[1], y + n[2])
        table.insert(octotree[x + n[1]][y + n[2]], entity)
    end
end


function M.octotree_foreach(entity, callback)
    local x = math.floor(entity.position.x / cell_size)
    local y = math.floor(entity.position.y / cell_size)
    check_octotree_cell(x, y)

    local entities = octotree[x][y]
    for index = 1, #entities do
        if entity ~= entities[index] then
            callback(entities[index])
        end
    end
end


function M.octotree_mark_dirty(entity)

end


function M.octotree_get_for(entity)
    local x = math.floor(entity.position.x / cell_size)
    local y = math.floor(entity.position.y / cell_size)
    check_octotree_cell(x, y)
    return octotree[x][y]
end


return M
