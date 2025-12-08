extends Resource
class_name WorldGrid

const DIRS: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var width: int = 0
var height: int = 0
var cells: Array = [] # 2D array [width][height]

func init(new_width: int, new_height: int) -> void:
    width = new_width
    height = new_height
    cells.resize(width)
    for x in width:
        cells[x] = []
        cells[x].resize(height)
        for y in height:
            var cell: CellData = CellData.new()
            cell.x = x
            cell.y = y
            cell.pass_cost = 1.0
            cells[x][y] = cell

func in_bounds(x: int, y: int) -> bool:
    return x >= 0 and y >= 0 and x < width and y < height

func get_cell(x: int, y: int) -> CellData:
    if not in_bounds(x, y):
        return null
    return cells[x][y]

func neighbors4(x: int, y: int) -> Array[Vector2i]:
    var result: Array[Vector2i] = []
    for dir in DIRS:
        var nx: int = x + dir.x
        var ny: int = y + dir.y
        if in_bounds(nx, ny):
            result.append(Vector2i(nx, ny))
    return result

func compute_pass_cost(cell: CellData) -> float:
    match cell.terrain_type:
        "mountain":
            return 9999.0
        "hill":
            return 2.0
        "forest":
            return 1.5
        "swamp":
            return 2.5
        "river":
            return 3.0
        "field":
            return 1.0
        "coast":
            return 1.2
        _:
            return 1.0

func _heuristic(a: Vector2i, b: Vector2i) -> float:
    return abs(a.x - b.x) + abs(a.y - b.y)

func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
    if not in_bounds(start.x, start.y) or not in_bounds(goal.x, goal.y):
        return []
    if start == goal:
        return [start]

    var open_set: Array[Vector2i] = [start]
    var came_from: Dictionary = {}
    var g_score: Dictionary = {start: 0.0}
    var f_score: Dictionary = {start: _heuristic(start, goal)}

    while open_set:
        open_set.sort_custom(func(a, b): return f_score.get(a, INF) < f_score.get(b, INF))
        var current: Vector2i = open_set.pop_front()
        if current == goal:
            return _reconstruct_path(came_from, current)

        for neighbor in neighbors4(current.x, current.y):
            var neighbor_cell: CellData = get_cell(neighbor.x, neighbor.y)
            if neighbor_cell == null or not neighbor_cell.is_passable():
                continue
            var tentative_g: float = g_score[current] + neighbor_cell.pass_cost
            if tentative_g < g_score.get(neighbor, INF):
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + _heuristic(neighbor, goal)
                if neighbor not in open_set:
                    open_set.append(neighbor)

    return []

func _reconstruct_path(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
    var path: Array[Vector2i] = [current]
    while came_from.has(current):
        current = came_from[current]
        path.push_front(current)
    return path
