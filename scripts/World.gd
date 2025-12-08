extends Node2D

@onready var terrain_tilemap: TileMap = $TerrainTileMap
@onready var road_tilemap: TileMap = $RoadTileMap
@onready var agents_root: Node2D = $AgentsRoot
@onready var settlements_root: Node2D = $SettlementsRoot
@onready var camera: Camera2D = $Camera2D

var grid: WorldGrid
var width: int = 64
var height: int = 64
var day: int = 0
var seconds_per_day: float = 0.5
var _time_accum: float = 0.0
var agents: Array[Agent] = []
var settlements: Array[Settlement] = []
var realms: Array[Realm] = []
var agent_nodes := {}
var settlement_nodes := {}

var _terrain_tileset: TileSet
var _terrain_sources := {}

func _ready() -> void:
    randomize()
    grid = WorldGrid.new()
    grid.init(width, height)
    _terrain_tileset = _build_tileset()
    terrain_tilemap.tile_set = _terrain_tileset
    road_tilemap.tile_set = _terrain_tileset
    _generate_terrain()
    _refresh_tiles()
    _create_starting_settlement()

func _process(delta: float) -> void:
    _time_accum += delta
    if _time_accum >= seconds_per_day:
        _time_accum -= seconds_per_day
        day += 1
        simulate_day()
    _update_camera(delta)

func _update_camera(delta: float) -> void:
    var move := Vector2.ZERO
    var speed := 200.0
    if Input.is_action_pressed("ui_right"):
        move.x += 1
    if Input.is_action_pressed("ui_left"):
        move.x -= 1
    if Input.is_action_pressed("ui_down"):
        move.y += 1
    if Input.is_action_pressed("ui_up"):
        move.y -= 1
    if move.length() > 0:
        camera.position += move.normalized() * speed * delta

func simulate_day() -> void:
    update_markets()
    agents_choose_jobs()
    agents_do_jobs()
    agents_consume_and_age()
    social_phase()
    politics_phase()

func update_markets() -> void:
    for settlement in settlements:
        settlement.market.daily_demand.clear()
        settlement.market.daily_supply.clear()
    for agent in agents:
        if not agent.alive:
            continue
        var market := get_nearest_market(agent.pos)
        match agent.daily_action:
            "woodcut":
                market.register_sell_request("wood", 1.0)
                market.register_buy_request("food", 1.0)
            "hunt":
                market.register_sell_request("meat", 0.8)
                market.register_buy_request("food", 0.5)
            "farm":
                market.register_sell_request("grain", 0.6)
                market.register_buy_request("food", 0.8)
            _:
                market.register_buy_request("food", 0.4)
    for settlement in settlements:
        settlement.market.resolve_trades()

func agents_choose_jobs() -> void:
    for agent in agents:
        if agent.alive:
            agent.choose_daily_action(self)

func agents_do_jobs() -> void:
    for agent in agents:
        if not agent.alive:
            continue
        var cell := grid.get_cell(agent.pos.x, agent.pos.y)
        if cell == null:
            continue
        match agent.daily_action:
            "woodcut":
                var amount := agent.skills.get("woodcut", 0.2) * (0.5 + cell.forest_density)
                agent.add_inventory("wood", amount)
            "hunt":
                var meat := agent.skills.get("hunt", 0.2) * (0.3 + cell.base_resources.get("game", 0.2))
                agent.add_inventory("meat", meat)
                agent.add_inventory("food", meat * 0.5)
            "farm":
                var grain := agent.skills.get("farm", 0.2) * (0.5 + cell.fertility)
                agent.add_inventory("grain", grain)
                agent.add_inventory("food", grain * 0.6)
            _:
                pass

func agents_consume_and_age() -> void:
    var deaths: Array[Agent] = []
    for agent in agents:
        if not agent.alive:
            continue
        var eaten := agent.consume_food(1.0)
        if eaten < 1.0:
            if randf() < 0.2:
                agent.alive = false
                deaths.append(agent)
                continue
        if randi() % 7 == 0:
            agent.age += 1
            if agent.age > 70 and randf() < 0.1:
                agent.alive = false
                deaths.append(agent)
    for dead in deaths:
        if dead.settlement_id != -1:
            var s := _get_settlement(dead.settlement_id)
            if s:
                s.population_ids.erase(dead.id)
        if agent_nodes.has(dead.id):
            agent_nodes[dead.id].queue_free()
            agent_nodes.erase(dead.id)

func social_phase() -> void:
    for settlement in settlements:
        var ids := settlement.population_ids.duplicate()
        ids.shuffle()
        for i in range(0, ids.size(), 2):
            if i + 1 >= ids.size():
                break
            var a := _get_agent(ids[i])
            var b := _get_agent(ids[i + 1])
            if a == null or b == null:
                continue
            var key := str(b.id)
            a.relationships[key] = a.relationships.get(key, 0.0) + 0.05
            key = str(a.id)
            b.relationships[key] = b.relationships.get(key, 0.0) + 0.05
        if settlement.population_ids.size() > 5 and randf() < 0.05:
            _spawn_child(settlement)

func _spawn_child(settlement: Settlement) -> void:
    # Very simple demographic growth: pick two parents and create a new child nearby.
    if settlement.population_ids.size() < 2:
        return
    var parent_a := _get_agent(settlement.population_ids[0])
    var parent_b := _get_agent(settlement.population_ids[1])
    if parent_a == null or parent_b == null:
        return
    var pos := settlement.pos + Vector2i(randi_range(-1, 1), randi_range(-1, 1))
    pos.x = clamp(pos.x, 0, width - 1)
    pos.y = clamp(pos.y, 0, height - 1)
    var child := _create_agent(pos)
    child.age = 0
    child.skills["woodcut"] = (parent_a.skills.get("woodcut", 0.2) + parent_b.skills.get("woodcut", 0.2)) / 2.0 + randf_range(-0.05, 0.05)
    child.skills["farm"] = (parent_a.skills.get("farm", 0.2) + parent_b.skills.get("farm", 0.2)) / 2.0 + randf_range(-0.05, 0.05)
    child.skills["hunt"] = (parent_a.skills.get("hunt", 0.2) + parent_b.skills.get("hunt", 0.2)) / 2.0 + randf_range(-0.05, 0.05)
    settlement.add_agent(child)

func politics_phase() -> void:
    update_settlement_growth()
    update_realms()

func update_settlement_growth() -> void:
    for settlement in settlements:
        if settlement.population_ids.size() > 25 and randf() < 0.02:
            var target := settlement.pos + Vector2i(randi_range(-6, 6), randi_range(-6, 6))
            if grid.in_bounds(target.x, target.y) and grid.get_cell(target.x, target.y).settlement_id == -1:
                var new_settlement := _create_settlement(target, "Hamlet %d" % settlements.size())
                # Move a few agents over
                var moved := 0
                for agent in agents:
                    if moved >= 3:
                        break
                    if agent.settlement_id == settlement.id and agent.alive:
                        settlement.remove_agent(agent)
                        new_settlement.add_agent(agent)
                        agent.pos = target
                        _ensure_agent_node(agent)
                        moved += 1

func update_realms() -> void:
    for settlement in settlements:
        if settlement.realm_id == -1 and settlement.population_ids.size() > 10:
            var realm := Realm.new(realms.size())
            realm.name = "Realm %d" % realm.id
            realm.capital_settlement_id = settlement.id
            realm.add_settlement(settlement.id)
            realm.color = Color.from_hsv(randf(), 0.6, 0.8)
            realms.append(realm)
            settlement.realm_id = realm.id
    # Simple dominance claim
    if realms.size() >= 2 and randf() < 0.02:
        var attacker := realms[randi() % realms.size()]
        var defender := realms[randi() % realms.size()]
        if attacker == defender:
            return
        if defender.settlement_ids.size() > 0:
            var captured := defender.settlement_ids.pop_back()
            attacker.add_settlement(captured)
            var settlement := _get_settlement(captured)
            if settlement:
                settlement.realm_id = attacker.id
            # TODO: add war state tracking

func handle_click(mouse_pos: Vector2) -> void:
    var local_mouse := to_local(mouse_pos)
    var clicked := false
    for node in agents_root.get_children():
        if node is Node2D and node.has_method("is_mouse_over"):
            if node.is_mouse_over(local_mouse):
                GameState.select_agent(node.agent)
                clicked = true
                break
    if clicked:
        return
    for node in settlements_root.get_children():
        if node.has_method("is_mouse_over") and node.is_mouse_over(local_mouse):
            GameState.select_settlement(node.settlement)
            clicked = true
            break
    if not clicked:
        GameState.clear_selection()

func get_population_count() -> int:
    var total := 0
    for agent in agents:
        if agent.alive:
            total += 1
    return total

func get_nearest_market(pos: Vector2i) -> Market:
    var best: Settlement = null
    var best_dist := INF
    for s in settlements:
        var d := pos.distance_to(s.pos)
        if d < best_dist:
            best = s
            best_dist = d
    if best:
        return best.market
    return Market.new()

func _generate_terrain() -> void:
    var elevation_noise := FastNoiseLite.new()
    elevation_noise.seed = randi()
    elevation_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    elevation_noise.frequency = 0.015

    var moisture_noise := FastNoiseLite.new()
    moisture_noise.seed = randi()
    moisture_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
    moisture_noise.frequency = 0.02

    for x in width:
        for y in height:
            var cell := grid.get_cell(x, y)
            var elev := elevation_noise.get_noise_2d(x, y)
            var moist := moisture_noise.get_noise_2d(x, y)
            if elev > 0.55:
                cell.terrain_type = "mountain"
            elif elev > 0.3:
                cell.terrain_type = "hill"
            elif elev < -0.4:
                cell.terrain_type = "water"
            elif elev < -0.2:
                cell.terrain_type = "coast"
            elif moist > 0.35:
                cell.terrain_type = "forest"
            elif moist < -0.3:
                cell.terrain_type = "swamp"
            else:
                cell.terrain_type = "field"
            cell.fertility = clamp(0.5 + moist - abs(elev) * 0.3, 0.0, 1.0)
            cell.forest_density = clamp(0.5 + moist, 0.0, 1.0)
            cell.base_resources["wood"] = cell.forest_density
            cell.base_resources["game"] = clamp(0.2 + moist, 0.0, 1.0)
            cell.pass_cost = grid.compute_pass_cost(cell)

func _refresh_tiles() -> void:
    terrain_tilemap.clear()
    for x in width:
        for y in height:
            var cell := grid.get_cell(x, y)
            var source_id := _terrain_sources.get(cell.terrain_type, _terrain_sources.get("field", 0))
            terrain_tilemap.set_cell(0, Vector2i(x, y), source_id, Vector2i.ZERO)

func _build_tileset() -> TileSet:
    var tile_set := TileSet.new()
    var color_map := {
        "field": Color(0.65, 0.8, 0.4),
        "forest": Color(0.1, 0.5, 0.1),
        "hill": Color(0.5, 0.45, 0.3),
        "mountain": Color(0.5, 0.5, 0.5),
        "water": Color(0.2, 0.4, 0.8),
        "swamp": Color(0.25, 0.35, 0.25),
        "coast": Color(0.3, 0.6, 0.7),
        "road": Color(0.7, 0.6, 0.4),
    }
    for terrain_type in color_map.keys():
        var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
        img.fill(color_map[terrain_type])
        var tex := ImageTexture.create_from_image(img)
        var source := TileSetAtlasSource.new()
        source.texture = tex
        source.create_tile(Vector2i.ZERO)
        var id := tile_set.add_source(source)
        _terrain_sources[terrain_type] = id
    return tile_set

func _create_starting_settlement() -> void:
    var center := Vector2i(width / 2, height / 2)
    for attempt in range(200):
        var pos := Vector2i(randi() % width, randi() % height)
        var cell := grid.get_cell(pos.x, pos.y)
        if cell and cell.is_passable() and cell.fertility > 0.3:
            center = pos
            break
    _create_settlement(center, "Home")
    for i in range(15):
        var offset := Vector2i(randi_range(-3, 3), randi_range(-3, 3))
        var pos := center + offset
        pos.x = clamp(pos.x, 0, width - 1)
        pos.y = clamp(pos.y, 0, height - 1)
        _create_agent(pos)

func _create_settlement(pos: Vector2i, name: String) -> Settlement:
    var settlement := Settlement.new(settlements.size())
    settlement.pos = pos
    settlement.name = name
    settlements.append(settlement)
    grid.get_cell(pos.x, pos.y).settlement_id = settlement.id
    _ensure_settlement_node(settlement)
    return settlement

func _create_agent(pos: Vector2i) -> Agent:
    var agent := Agent.new(agents.size())
    agent.name = "Peasant %d" % agent.id
    agent.pos = pos
    agent.gender = randf() < 0.5 ? "male" : "female"
    agents.append(agent)
    for settlement in settlements:
        if settlement.pos.distance_to(pos) < 4:
            settlement.add_agent(agent)
            break
    _ensure_agent_node(agent)
    return agent

func _ensure_agent_node(agent: Agent) -> void:
    if agent_nodes.has(agent.id):
        return
    var scene := preload("res://scenes/Agent.tscn")
    var instance: Node2D = scene.instantiate()
    instance.agent = agent
    agents_root.add_child(instance)
    agent_nodes[agent.id] = instance

func _ensure_settlement_node(settlement: Settlement) -> void:
    if settlement_nodes.has(settlement.id):
        return
    var scene := preload("res://scenes/Settlement.tscn")
    var instance: Node2D = scene.instantiate()
    instance.settlement = settlement
    settlements_root.add_child(instance)
    settlement_nodes[settlement.id] = instance

func _get_agent(id: int) -> Agent:
    if id >= 0 and id < agents.size():
        return agents[id]
    return null

func _get_settlement(id: int) -> Settlement:
    if id >= 0 and id < settlements.size():
        return settlements[id]
    return null
