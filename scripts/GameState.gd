extends Node

var world: Node = null
var selected_agent: Agent = null
var selected_settlement: Settlement = null

signal selection_changed

func set_world(world_node: Node) -> void:
    world = world_node

func select_agent(agent: Agent) -> void:
    selected_agent = agent
    selected_settlement = null
    emit_signal("selection_changed")

func select_settlement(settlement: Settlement) -> void:
    selected_settlement = settlement
    selected_agent = null
    emit_signal("selection_changed")

func clear_selection() -> void:
    selected_agent = null
    selected_settlement = null
    emit_signal("selection_changed")
