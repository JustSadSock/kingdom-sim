extends Resource
class_name Agent

var id: int = 0
var name: String = "Peasant"
var pos: Vector2i = Vector2i.ZERO
var age: int = 18
var alive: bool = true
var gender: String = "male"
var family_id: int = -1
var settlement_id: int = -1
var money: float = 0.0
var inventory := {
    "food": 2.0,
    "wood": 0.0,
    "meat": 0.0,
    "grain": 0.0,
}
var skills := {
    "woodcut": 0.3,
    "hunt": 0.3,
    "farm": 0.3,
    "build": 0.1,
    "soldier": 0.1,
}
var relationships := {} # agent_id -> float
var daily_action: String = ""

func _init(new_id: int = 0):
    id = new_id

func estimate_income_for_action(world: Node, action: String) -> float:
    # Rough estimate based on terrain and skills.
    var terrain := world.grid.get_cell(pos.x, pos.y)
    if terrain == null:
        return 0.0
    var market := world.get_nearest_market(pos)
    var price_food := market.prices.get("food", 1.0)
    var price_wood := market.prices.get("wood", 0.5)

    match action:
        "woodcut":
            var base := skills.get("woodcut", 0.2) * (0.5 + terrain.forest_density)
            return base * price_wood
        "hunt":
            var base_hunt := skills.get("hunt", 0.2) * (0.3 + terrain.base_resources.get("game", 0.1))
            return base_hunt * price_food * 0.8
        "farm":
            var base_farm := skills.get("farm", 0.2) * (0.5 + terrain.fertility)
            return base_farm * price_food
        "idle":
            return 0.1
        _:
            return 0.0

func choose_daily_action(world: Node) -> void:
    var options := ["woodcut", "hunt", "farm", "idle"]
    var best_action := "idle"
    var best_value := -INF
    for action in options:
        var income := estimate_income_for_action(world, action)
        income += randf_range(-0.05, 0.05) # small randomness
        if income > best_value:
            best_value = income
            best_action = action
    daily_action = best_action

func add_inventory(item: String, amount: float) -> void:
    inventory[item] = inventory.get(item, 0.0) + amount

func consume_food(amount: float) -> float:
    var remaining := amount
    for food_key in ["food", "grain", "meat"]:
        var available := inventory.get(food_key, 0.0)
        var take := min(available, remaining)
        inventory[food_key] = available - take
        remaining -= take
        if remaining <= 0:
            break
    return amount - remaining
