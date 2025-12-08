extends Resource
class_name Settlement

var id: int = 0
var name: String = "Village"
var pos: Vector2i = Vector2i.ZERO
var population_ids: Array[int] = []
var market: Market = Market.new()
var realm_id: int = -1

func _init(new_id: int = 0):
    id = new_id
    market.settlement_id = id

func add_agent(agent: Agent) -> void:
    if agent.id not in population_ids:
        population_ids.append(agent.id)
        agent.settlement_id = id

func remove_agent(agent: Agent) -> void:
    population_ids.erase(agent.id)
    if agent.settlement_id == id:
        agent.settlement_id = -1
