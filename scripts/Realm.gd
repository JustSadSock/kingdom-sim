extends Resource
class_name Realm

var id: int = 0
var name: String = "Realm"
var capital_settlement_id: int = -1
var settlement_ids: Array[int] = []
var color: Color = Color(0.6, 0.2, 0.2)
var legitimacy: float = 0.7
var military_strength: float = 0.0

func _init(new_id: int = 0):
    id = new_id

func add_settlement(settlement_id: int) -> void:
    if settlement_id not in settlement_ids:
        settlement_ids.append(settlement_id)

func remove_settlement(settlement_id: int) -> void:
    settlement_ids.erase(settlement_id)
