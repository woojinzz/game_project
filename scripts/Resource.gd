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
	# 자원 타입별 다른 도트 그래픽
	var resource_types = ["grain", "meat", "carrot", "berry"]
	var type_index = randi() % resource_types.size()
	resource_type = resource_types[type_index]
	
	create_pixel_art_resource(type_index)

func create_pixel_art_resource(type_index: int):
	# 도트 그래픽 컨테이너
	var pixel_container = Node2D.new()
	pixel_container.name = "PixelArt"
	add_child(pixel_container)
	
	# 12x12 도트 자원 생성
	var pixel_size = 0.6  # 각 픽셀당 0.6x0.6 크기 (훨씬 더 작게)
	var resource_pixels = get_resource_pixel_pattern(type_index)
	
	for y in range(resource_pixels.size()):
		for x in range(resource_pixels[y].size()):
			var pixel_color = resource_pixels[y][x]
			if pixel_color != Color.TRANSPARENT:
				var pixel = ColorRect.new()
				pixel.size = Vector2(pixel_size, pixel_size)
				pixel.position = Vector2(
					(x - 6) * pixel_size,  # 중앙 정렬
					(y - 6) * pixel_size
				)
				pixel.color = pixel_color
				pixel_container.add_child(pixel)
	
	# 깜빡이는 효과로 자원임을 표시
	add_sparkle_effect()

func get_resource_pixel_pattern(type_index: int) -> Array:
	var t = Color.TRANSPARENT
	
	match type_index:
		0:  # 곡물 (grain)
			var grain_color = Color(0.8, 0.7, 0.2)  # 황금색
			var stem_color = Color(0.2, 0.6, 0.1)   # 녹색
			return [
				[t,t,t,grain_color,grain_color,grain_color,grain_color,grain_color,t,t,t,t],
				[t,t,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,t,t,t],
				[t,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,t,t],
				[t,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,t,t],
				[t,t,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,grain_color,t,t,t],
				[t,t,t,grain_color,grain_color,grain_color,grain_color,grain_color,t,t,t,t],
				[t,t,t,t,stem_color,stem_color,stem_color,t,t,t,t,t],
				[t,t,t,t,stem_color,stem_color,stem_color,t,t,t,t,t],
				[t,t,t,t,stem_color,stem_color,stem_color,t,t,t,t,t],
				[t,t,t,t,stem_color,stem_color,stem_color,t,t,t,t,t],
				[t,t,t,t,stem_color,stem_color,stem_color,t,t,t,t,t],
				[t,t,t,t,t,t,t,t,t,t,t,t]
			]
		1:  # 고기 (meat)
			var meat_color = Color(0.6, 0.2, 0.1)   # 빨간 갈색
			var bone_color = Color(0.9, 0.9, 0.8)   # 뼈색
			return [
				[t,t,t,t,t,t,t,t,t,t,t,t],
				[t,t,bone_color,bone_color,t,t,t,t,bone_color,bone_color,t,t],
				[t,t,bone_color,bone_color,meat_color,meat_color,meat_color,meat_color,bone_color,bone_color,t,t],
				[t,t,t,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,t,t,t],
				[t,t,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,t,t],
				[t,t,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,t,t],
				[t,t,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,t,t],
				[t,t,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,t,t],
				[t,t,t,meat_color,meat_color,meat_color,meat_color,meat_color,meat_color,t,t,t],
				[t,t,t,t,meat_color,meat_color,meat_color,meat_color,t,t,t,t],
				[t,t,t,t,t,meat_color,meat_color,t,t,t,t,t],
				[t,t,t,t,t,t,t,t,t,t,t,t]
			]
		2:  # 당근 (carrot)
			var carrot_color = Color(0.9, 0.4, 0.1)  # 주황색
			var leaf_color = Color(0.1, 0.7, 0.2)    # 초록
			return [
				[t,t,t,t,leaf_color,leaf_color,leaf_color,leaf_color,t,t,t,t],
				[t,t,t,leaf_color,leaf_color,leaf_color,leaf_color,leaf_color,leaf_color,t,t,t],
				[t,t,leaf_color,leaf_color,leaf_color,leaf_color,leaf_color,leaf_color,leaf_color,leaf_color,t,t],
				[t,t,t,t,carrot_color,carrot_color,carrot_color,carrot_color,t,t,t,t],
				[t,t,t,carrot_color,carrot_color,carrot_color,carrot_color,carrot_color,carrot_color,t,t,t],
				[t,t,t,carrot_color,carrot_color,carrot_color,carrot_color,carrot_color,carrot_color,t,t,t],
				[t,t,t,t,carrot_color,carrot_color,carrot_color,carrot_color,t,t,t,t],
				[t,t,t,t,carrot_color,carrot_color,carrot_color,carrot_color,t,t,t,t],
				[t,t,t,t,t,carrot_color,carrot_color,t,t,t,t,t],
				[t,t,t,t,t,carrot_color,carrot_color,t,t,t,t,t],
				[t,t,t,t,t,t,carrot_color,t,t,t,t,t],
				[t,t,t,t,t,t,t,t,t,t,t,t]
			]
		3:  # 베리 (berry)
			var berry_color = Color(0.5, 0.1, 0.7)   # 보라색
			var highlight = Color(0.7, 0.3, 0.8)     # 밝은 보라
			return [
				[t,t,t,t,t,t,t,t,t,t,t,t],
				[t,t,t,berry_color,berry_color,t,t,berry_color,berry_color,t,t,t],
				[t,t,berry_color,highlight,berry_color,berry_color,berry_color,berry_color,highlight,berry_color,t,t],
				[t,t,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,t,t],
				[t,berry_color,berry_color,highlight,berry_color,berry_color,berry_color,berry_color,highlight,berry_color,berry_color,t],
				[t,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,t],
				[berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color],
				[berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color],
				[t,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,t],
				[t,t,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,t,t],
				[t,t,t,berry_color,berry_color,berry_color,berry_color,berry_color,berry_color,t,t,t],
				[t,t,t,t,t,t,t,t,t,t,t,t]
			]
		_:
			return []

func add_sparkle_effect():
	# 자원에 반짝이는 효과 추가
	var sparkle_timer = Timer.new()
	sparkle_timer.wait_time = 2.0 + randf() * 2.0  # 2-4초 간격
	sparkle_timer.timeout.connect(_on_sparkle)
	sparkle_timer.autostart = true
	add_child(sparkle_timer)

func _on_sparkle():
	# 작은 별 이펙트
	var sparkle = Label.new()
	sparkle.text = "✨"
	sparkle.position = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	sparkle.add_theme_font_size_override("font_size", 6)
	sparkle.modulate = Color(1, 1, 1, 0.8)
	add_child(sparkle)
	
	# 1초 후 사라짐
	var tween = create_tween()
	tween.tween_property(sparkle, "modulate:a", 0.0, 1.0)
	tween.tween_callback(sparkle.queue_free)

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
		randf_range(16, 200 * 32 - 16),  # 맵 너비 200으로 확대
		randf_range(16, 120 * 32 - 16)   # 맵 높이 120으로 확대
	)
	global_position = new_pos