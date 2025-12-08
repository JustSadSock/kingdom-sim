extends Resource
class_name CellData

## Stores terrain and ownership information for one grid cell.
var x: int
var y: int
var terrain_type: String = "field"
var fertility: float = 0.5
var forest_density: float = 0.0
var pass_cost: float = 1.0
var base_resources := {
    "wood": 0.0,
    "game": 0.0,
    "grain": 0.0,
    "stone": 0.0,
    "ore": 0.0,
}
var settlement_id: int = -1
var owner_realm_id: int = -1
var market_access: float = 0.0

func is_passable() -> bool:
    # Block movement through very rough terrain.
    match terrain_type:
        "mountain", "water", "ocean":
            return false
        _:
            return true
