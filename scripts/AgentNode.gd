extends Node2D

@export var agent: Agent
var _sprite: Sprite2D

func _ready() -> void:
    _sprite = Sprite2D.new()
    add_child(_sprite)
    if _sprite.texture == null:
        _sprite.texture = _make_circle_texture(Color(0.8, 0.9, 1.0))
    _sprite.centered = true
    _sprite.modulate = Color(0.9, 0.7, 0.9) if agent.gender == "female" else Color(0.7, 0.9, 0.7)
    _sprite.scale = Vector2(0.5, 0.5)

func _process(_delta: float) -> void:
    if agent == null:
        return
    position = agent.pos * 16 # 16 pixels per tile

func is_mouse_over(mouse_pos: Vector2) -> bool:
    return position.distance_to(mouse_pos) < 8.0

func _make_circle_texture(color: Color) -> Texture2D:
    var img: Image = Image.create(16, 16, false, Image.FORMAT_RGBA8)
    for x in 16:
        for y in 16:
            var center := Vector2(7.5, 7.5)
            var dist := center.distance_to(Vector2(x, y))
            if dist <= 7.0:
                img.set_pixel(x, y, color)
            else:
                img.set_pixel(x, y, Color(0, 0, 0, 0))
    return ImageTexture.create_from_image(img)
