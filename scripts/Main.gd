extends Node2D

@onready var world: World = $World
@onready var hud: Control = $HUD

func _ready() -> void:
    GameState.set_world(world)

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        world.handle_click(get_global_mouse_position())
