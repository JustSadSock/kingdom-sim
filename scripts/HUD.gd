extends Control

@onready var day_label: Label = $VBoxContainer/DayLabel
@onready var population_label: Label = $VBoxContainer/PopulationLabel
@onready var settlements_label: Label = $VBoxContainer/SettlementsLabel
@onready var realms_label: Label = $VBoxContainer/RealmsLabel
@onready var selection_panel: VBoxContainer = $VBoxContainer/SelectionPanel
@onready var selection_label: Label = $VBoxContainer/SelectionPanel/SelectionLabel
@onready var details_label: Label = $VBoxContainer/SelectionPanel/DetailsLabel

var game_state: GameState

func _ready() -> void:
    game_state = GameState
    game_state.selection_changed.connect(_on_selection_changed)
    _refresh_ui()

func _process(_delta: float) -> void:
    _refresh_ui()

func _refresh_ui() -> void:
    if game_state.world:
        day_label.text = "Day: " + str(game_state.world.day)
        population_label.text = "Population: " + str(game_state.world.get_population_count())
        settlements_label.text = "Settlements: " + str(game_state.world.settlements.size())
        realms_label.text = "Realms: " + str(game_state.world.realms.size())
    _update_selection_panel()

func _on_selection_changed() -> void:
    _update_selection_panel()

func _update_selection_panel() -> void:
    if game_state.selected_agent:
        var agent: Agent = game_state.selected_agent
        selection_label.text = "Agent: %s (age %s)" % [agent.name, agent.age]
        details_label.text = "Action: %s\nInventory: %s\nSkills: %s" % [agent.daily_action, agent.inventory, agent.skills]
        selection_panel.visible = true
    elif game_state.selected_settlement:
        var settlement: Settlement = game_state.selected_settlement
        selection_label.text = "Settlement: %s" % settlement.name
        details_label.text = "Population: %s\nRealm: %s\nStock: %s" % [settlement.population_ids.size(), _get_realm_name(settlement.realm_id), settlement.market.stock]
        selection_panel.visible = true
    else:
        selection_panel.visible = false

func _get_realm_name(realm_id: int) -> String:
    if realm_id == -1:
        return "None"
    for realm in game_state.world.realms:
        if realm.id == realm_id:
            return realm.name
    return "Unknown"
