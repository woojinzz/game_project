extends Area2D

var resource_type = "food"
var value = 1.0
var respawn_timer = 0.0
var respawn_time = 10.0
var is_consumed = false

func setup(pos):
	global_position = pos
	create_visual()
	setup_collision()
	connect_signals()

func create_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(12, 12)
	sprite.position = Vector2(-6, -6)
	sprite.color = Color.YELLOW
	add_child(sprite)

func setup_collision():
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 6
	collision_shape.shape = shape
	add_child(collision_shape)

func connect_signals():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method("consume_resource") and not is_consumed:
		is_consumed = true
		visible = false
		collision_layer = 0
		collision_mask = 0
		start_respawn_timer()

func start_respawn_timer():
	respawn_timer = respawn_time

func _process(delta):
	if is_consumed:
		respawn_timer -= delta
		if respawn_timer <= 0:
			respawn()

func respawn():
	is_consumed = false
	visible = true
	collision_layer = 1
	collision_mask = 1
	
	var new_pos = Vector2(
		randf_range(16, 50 * 32 - 16),
		randf_range(16, 30 * 32 - 16)
	)
	global_position = new_pos