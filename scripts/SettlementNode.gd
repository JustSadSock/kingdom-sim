extends Node2D

@export var settlement: Settlement
var _sprite: Sprite2D
var _label: Label

func _ready() -> void:
    _sprite = Sprite2D.new()
    _sprite.texture = _make_square_texture(Color(0.9, 0.8, 0.6))
    _sprite.centered = true
    _sprite.scale = Vector2(1, 1)
    add_child(_sprite)

    _label = Label.new()
    _label.text = settlement.name
    _label.position = Vector2(-24, -20)
    add_child(_label)

func _process(_delta: float) -> void:
    if settlement:
        position = settlement.pos * 16
        _label.text = settlement.name + " (" + str(settlement.population_ids.size()) + ")"

func is_mouse_over(mouse_pos: Vector2) -> bool:
    return position.distance_to(mouse_pos) < 12.0

func _make_square_texture(color: Color) -> Texture2D:
    var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
    img.fill(color)
    return ImageTexture.create_from_image(img)
