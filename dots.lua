pico-8 cartridge // http://www.pico-8.com
version 41
__lua__

-- Constants
FOV = 60 -- Field of View
HALF_WIDTH = 64 -- Half of the screen width
HALF_HEIGHT = 64 -- Half of the screen height
NEAR_PLANE = 0.1 -- Near clipping plane
FAR_PLANE = 100 -- Far clipping plane

screen_width = 128

max_speed = 0.7

player = {
    pos = { x = 0, y = -1, z = -2 },
    rot = { x = 0, y = 0, z = 0 },
}

-- Camera
camera = {
    pos = { x = 0, y = 0, z = 0 },
    rot = { x = 0, y = 0, z = 0 },
}

cls()

function _init()   
end

function qsort_by_sum_z(lines, compare)
    compare = compare or function(a, b) return a < b end

    local function line_sum_z(line)
        return line[1].z + line[2].z
    end

    local function partition(list, low, high)
        local pivot = list[high]
        local i = low - 1

        for j = low, high - 1 do
            if compare(line_sum_z(pivot), line_sum_z(list[j])) then
                i = i + 1
                list[i], list[j] = list[j], list[i]
            end
        end

        list[i + 1], list[high] = list[high], list[i + 1]
        return i + 1
    end

    local function quicksort(list, low, high)
        if low < high then
            local pivotIndex = partition(list, low, high)
            quicksort(list, low, pivotIndex - 1)
            quicksort(list, pivotIndex + 1, high)
        end
    end

    quicksort(lines, 1, #lines)
end

-- Perform perspective projection with rotation
function project(point, rot_angle)
    local dx = point.x - camera.pos.x
    local dy = point.y - camera.pos.y
    local dz = point.z - camera.pos.z

    -- Apply rotation to the point
    local rotated_x = dx * cos(rot_angle) + dz * sin(rot_angle)
    local rotated_z = -dx * sin(rot_angle) + dz * cos(rot_angle)

    local factor = FOV / (rotated_z + NEAR_PLANE)
    local x = rotated_x * factor + HALF_WIDTH
    local y = dy * factor + HALF_HEIGHT

    return { x = x, y = y, dz = dz }
end

function _draw()
    cls()

    for projected_point in all(projected_points) do
        pset(projected_point.x, projected_point.y, projected_point.color)
    end
end

points = {}

function add_dotted_line(x1, y1, z1, x2, y2, z2, step)
    local dx = x2 - x1
    local dy = y2 - y1
    local dz = z2 - z1

    local length = sqrt(dx * dx + dy * dy + dz * dz)
    local steps = length / step

    for i = 0, steps do
        local t = i / steps
        add(points, { x = x1 + dx * t, y = y1 + dy * t, z = z1 + dz * t })
    end
end

function add_corridor(x1, y1, z1, x2, y2, z2, width, height)
    -- upper
    add_dotted_line(x1 - width, y1, z1, x2 - width, y2, z2, 0.25)
    add_dotted_line(x1 + width, y1, z1, x2 + width, y2, z2, 0.25)
    
    -- lower
    add_dotted_line(x1 - width, y1 - height, z1, x2 - width, y2 - height, z2, 0.25)
    add_dotted_line(x1 + width, y1 - height, z1, x2 + width, y2 - height, z2, 0.25)
end

-- add_dotted_line(-1, -1, 0, -1, -1, 5, 0.2)
add_corridor(0, 1, 0, 1, 1, 5, 2, 3)

last_time = time()
delta_time = 0
angle = 0
angle_timer = 0

function _update()
    -- move player with buttons
    -- if btn(0) then
    --     player.pos.x -= 0.02
    -- elseif btn(1) then
    --     player.pos.x += 0.02
    -- end

    if btn(0) then
        player.rot.y -= 0.005
    elseif btn(1) then
        player.rot.y += 0.005
    end

    local move_speed = 0.03
    if btn(2) then
        player.pos.x += move_speed * sin(player.rot.y) * -1
        player.pos.z += move_speed * cos(player.rot.y)
    elseif btn(3) then
        player.pos.x -= move_speed * sin(player.rot.y) * -1
        player.pos.z -= move_speed * cos(player.rot.y)
    end

    camera.pos = player.pos
    camera.pos.y += sin(angle / 10) / 100

    camera.rot = player.rot

    projected_points = {}
    
    for point in all(points) do
        camera_z_diff = point.z - camera.pos.z
        if camera_z_diff > 0 then
            if camera_z_diff > 2 then
                color = 1
            elseif camera_z_diff > 1.5 then
                color = 2
            elseif camera_z_diff > 1 then
                color = 5
            elseif camera_z_diff > 0.6 then
                color = 6
            elseif camera_z_diff > 0.4 then
                color = 15
            else
                color = 7
            end

            projected_point = project(point, camera.rot.y)
            projected_point.color = color
        
            add(projected_points, projected_point)
        end
    end

    delta_time = time() - last_time
    angle_timer += delta_time
    last_time = time()

    if angle_timer >= 0.2 then
        angle = (angle + 1) % 10
        angle_timer = 0
    end
end
