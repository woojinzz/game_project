extends Control
class_name Minimap

@onready var minimap_viewport = $MinimapViewport
@onready var minimap_camera = $MinimapViewport/MinimapCamera

var game_manager
var map_size = Vector2(200, 120)  # 타일 기준 (4배 맵 확대에 맞춤)
var minimap_size = Vector2(200, 120)  # 픽셀 기준
var scale_factor = 1.0

# 성능 최적화용
var minimap_update_timer = 0.0
var minimap_update_interval = 0.2  # 0.2초마다 미니맵 업데이트

var agent_dots = []
var resource_dots = []

func _ready():
	setup_minimap()

func setup_minimap():
	# 미니맵 크기와 위치 설정 (화면 크기에 반응)
	var viewport_size = get_viewport().size
	var scale = min(1.0, min(viewport_size.x / 1280.0, viewport_size.y / 720.0))
	minimap_size = Vector2(200 * scale, 120 * scale)
	size = minimap_size
	position = Vector2(20, viewport_size.y - minimap_size.y - 20)  # 왼쪽 하단
	
	# 배경 설정
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1, 0.8)
	bg.size = minimap_size
	add_child(bg)
	bg.move_to_front()
	
	# 제목 라벨
	var title = Label.new()
	title.text = "🗺️ 미니맵"
	title.position = Vector2(5, 5)
	title.add_theme_font_size_override("font_size", max(8, int(minimap_size.x / 20)))
	title.add_theme_color_override("font_color", Color.WHITE)
	add_child(title)
	
	# 미니맵 컨테이너
	var minimap_container = Control.new()
	minimap_container.size = Vector2(minimap_size.x - 10, minimap_size.y - 25)
	minimap_container.position = Vector2(5, 20)
	add_child(minimap_container)
	
	# 스케일 팩터 계산
	scale_factor = min(
		(minimap_size.x - 10) / (map_size.x * 32),
		(minimap_size.y - 25) / (map_size.y * 32)
	)
	
	print("🗺️ 미니맵 초기화 완료 (스케일: ", scale_factor, ")")

func set_game_manager(manager):
	game_manager = manager

func _process(delta):
	if game_manager:
		# 타이머 기반 최적화된 미니맵 업데이트
		minimap_update_timer += delta
		if minimap_update_timer >= minimap_update_interval:
			minimap_update_timer = 0.0
			update_minimap()

func update_minimap():
	# 기존 도트들 제거
	clear_dots()
	
	if not game_manager:
		return
	
	# 에이전트 도트 생성
	for agent in game_manager.agents:
		if not is_instance_valid(agent):
			continue
		
		var dot = create_agent_dot(agent)
		if dot:
			agent_dots.append(dot)
			add_child(dot)
	
	# 자원 도트 생성
	for resource in game_manager.resources:
		if not is_instance_valid(resource) or not resource.visible:
			continue
		
		var dot = create_resource_dot(resource)
		if dot:
			resource_dots.append(dot)
			add_child(dot)

func clear_dots():
	for dot in agent_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	for dot in resource_dots:
		if is_instance_valid(dot):
			dot.queue_free()
	
	agent_dots.clear()
	resource_dots.clear()

func create_agent_dot(agent) -> Control:
	var dot_container = Control.new()
	var scale = min(1.0, minimap_size.x / 200.0)
	
	# 더 정교한 미니맵 에이전트 도트 (7x7 픽셀 아트)
	var pixel_size = max(1, int(1.2 * scale))
	var base_color = agent.tribe_color
	var dark_color = base_color.darkened(0.4)
	var light_color = base_color.lightened(0.3)
	var skin_color = Color(0.9, 0.8, 0.7)
	var t = Color.TRANSPARENT
	
	# 7x7 에이전트 도트 패턴 (미니맵용 세밀한 버전)
	var pattern = [
		[t, t, light_color, base_color, light_color, t, t],
		[t, base_color, skin_color, skin_color, skin_color, base_color, t],
		[light_color, skin_color, Color.BLACK, skin_color, Color.BLACK, skin_color, light_color],
		[base_color, skin_color, skin_color, Color.RED, skin_color, skin_color, base_color],
		[base_color, base_color, base_color, base_color, base_color, base_color, base_color],
		[t, base_color, base_color, base_color, base_color, base_color, t],
		[t, t, dark_color, t, dark_color, t, t]
	]
	
	# 선택된 에이전트는 더 크게 표시
	var size_multiplier = 1
	if game_manager and game_manager.agent_detail_panel and game_manager.agent_detail_panel.selected_agent == agent:
		size_multiplier = 2
		# 흰색 테두리 추가
		var outline = ColorRect.new()
		outline.size = Vector2(7 * pixel_size, 7 * pixel_size)
		outline.position = Vector2(-3.5 * pixel_size, -3.5 * pixel_size)
		outline.color = Color.WHITE
		dot_container.add_child(outline)
	
	# 건강 상태에 따른 색상 변화
	if agent.health < 30:
		# 체력이 낮으면 어둡게
		for i in range(pattern.size()):
			for j in range(pattern[i].size()):
				if pattern[i][j] != Color.TRANSPARENT:
					pattern[i][j] = pattern[i][j].darkened(0.3)
	
	# 패턴 그리기 (7x7)
	for y in range(7):
		for x in range(7):
			var pixel_color = pattern[y][x]
			if pixel_color != Color.TRANSPARENT:
				var pixel = ColorRect.new()
				pixel.size = Vector2(pixel_size * size_multiplier, pixel_size * size_multiplier)
				pixel.position = Vector2(
					(x - 3) * pixel_size * size_multiplier,
					(y - 3) * pixel_size * size_multiplier
				)
				pixel.color = pixel_color
				dot_container.add_child(pixel)
	
	# 위치 계산
	var minimap_pos = world_to_minimap(agent.global_position)
	dot_container.position = minimap_pos
	
	return dot_container

func create_resource_dot(resource) -> Control:
	var dot_container = Control.new()
	var scale = min(1.0, minimap_size.x / 200.0)
	
	# 더 정교한 미니맵 자원 표시 (5x5 픽셀 아트)
	var pixel_size = max(1, int(1.5 * scale))
	var resource_color = get_resource_minimap_color(resource.resource_type)
	var highlight = resource_color.lightened(0.4)
	var shadow = resource_color.darkened(0.3)
	var t = Color.TRANSPARENT
	
	# 5x5 자원별 세밀한 도트 패턴
	var pattern = []
	match resource.resource_type:
		"grain":
			pattern = [
				[t, highlight, resource_color, highlight, t],
				[highlight, resource_color, highlight, resource_color, highlight],
				[resource_color, highlight, resource_color, highlight, resource_color],
				[t, resource_color, shadow, resource_color, t],
				[t, t, shadow, t, t]
			]
		"meat":
			pattern = [
				[t, resource_color, resource_color, resource_color, t],
				[resource_color, highlight, resource_color, highlight, resource_color],
				[resource_color, resource_color, shadow, resource_color, resource_color],
				[t, resource_color, resource_color, resource_color, t],
				[t, t, shadow, t, t]
			]
		"carrot":
			var leaf = Color.GREEN
			pattern = [
				[t, leaf, leaf, leaf, t],
				[t, resource_color, highlight, resource_color, t],
				[t, resource_color, resource_color, resource_color, t],
				[t, t, resource_color, t, t],
				[t, t, shadow, t, t]
			]
		"berry":
			pattern = [
				[t, resource_color, t, resource_color, t],
				[resource_color, highlight, resource_color, highlight, resource_color],
				[t, resource_color, resource_color, resource_color, t],
				[t, t, resource_color, t, t],
				[t, t, shadow, t, t]
			]
		_:
			pattern = [
				[t, resource_color, resource_color, resource_color, t],
				[resource_color, highlight, resource_color, highlight, resource_color],
				[resource_color, resource_color, shadow, resource_color, resource_color],
				[t, resource_color, resource_color, resource_color, t],
				[t, t, shadow, t, t]
			]
	
	for y in range(5):
		for x in range(5):
			var pixel_color = pattern[y][x]
			if pixel_color != Color.TRANSPARENT:
				var pixel = ColorRect.new()
				pixel.size = Vector2(pixel_size, pixel_size)
				pixel.position = Vector2(
					(x - 2) * pixel_size,
					(y - 2) * pixel_size
				)
				pixel.color = pixel_color
				dot_container.add_child(pixel)
	
	# 위치 계산
	var minimap_pos = world_to_minimap(resource.global_position)
	dot_container.position = minimap_pos
	
	return dot_container

func get_resource_minimap_color(resource_type: String) -> Color:
	match resource_type:
		"grain":
			return Color.GOLD
		"meat":
			return Color(0.6, 0.2, 0.1)  # 갈색
		"carrot":
			return Color.ORANGE
		"berry":
			return Color(0.5, 0.1, 0.7)  # 보라색
		_:
			return Color.YELLOW

func world_to_minimap(world_pos: Vector2) -> Vector2:
	# 월드 좌표를 미니맵 좌표로 변환
	var normalized_pos = Vector2(
		world_pos.x / (map_size.x * 32),
		world_pos.y / (map_size.y * 32)
	)
	
	return Vector2(
		5 + normalized_pos.x * (minimap_size.x - 10),
		20 + normalized_pos.y * (minimap_size.y - 25)
	)

func minimap_to_world(minimap_pos: Vector2) -> Vector2:
	# 미니맵 좌표를 월드 좌표로 변환
	var relative_pos = Vector2(
		(minimap_pos.x - 5) / (minimap_size.x - 10),
		(minimap_pos.y - 20) / (minimap_size.y - 25)
	)
	
	return Vector2(
		relative_pos.x * map_size.x * 32,
		relative_pos.y * map_size.y * 32
	)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 미니맵 클릭 감지
			var local_pos = event.global_position - global_position
			if local_pos.x >= 0 and local_pos.x <= size.x and local_pos.y >= 0 and local_pos.y <= size.y:
				handle_minimap_click(local_pos)

func handle_minimap_click(click_pos: Vector2):
	if not game_manager or not game_manager.camera:
		return
	
	# 클릭 위치를 월드 좌표로 변환
	var world_pos = minimap_to_world(click_pos)
	
	# 카메라를 해당 위치로 이동
	game_manager.camera.global_position = world_pos
	
	print("🗺️ 미니맵 클릭: 카메라가 ", world_pos, "로 이동")

func get_minimap_info() -> Dictionary:
	var agent_count_by_tribe = {}
	var resource_count = 0
	
	if game_manager:
		for agent in game_manager.agents:
			if not is_instance_valid(agent):
				continue
			
			var tribe = agent.tribe
			agent_count_by_tribe[tribe] = agent_count_by_tribe.get(tribe, 0) + 1
		
		for resource in game_manager.resources:
			if is_instance_valid(resource) and resource.visible:
				resource_count += 1
	
	return {
		"agent_count_by_tribe": agent_count_by_tribe,
		"resource_count": resource_count,
		"scale": scale_factor
	}

func add_minimap_legend():
	# 범례 추가
	var legend_y = minimap_size.y - 80
	var scale = min(1.0, minimap_size.x / 200.0)
	
	# 부족 색상 범례
	var tribe_colors = [Color.RED, Color.BLUE, Color.GREEN, Color.YELLOW]
	var tribe_names = ["🔥불꽃", "🌊물결", "🌲숲속", "☀️태양"]
	
	var legend_container = VBoxContainer.new()
	legend_container.position = Vector2(5, legend_y)
	legend_container.size = Vector2(minimap_size.x - 10, 75)
	add_child(legend_container)
	
	# 부족 범례
	var tribe_title = Label.new()
	tribe_title.text = "부족:"
	tribe_title.add_theme_color_override("font_color", Color.WHITE)
	tribe_title.add_theme_font_size_override("font_size", max(8, int(10 * scale)))
	legend_container.add_child(tribe_title)
	
	for i in range(4):
		var tribe_row = HBoxContainer.new()
		legend_container.add_child(tribe_row)
		
		var legend_dot = ColorRect.new()
		legend_dot.size = Vector2(8 * scale, 8 * scale)
		legend_dot.color = tribe_colors[i]
		tribe_row.add_child(legend_dot)
		
		var legend_label = Label.new()
		legend_label.text = tribe_names[i]
		legend_label.add_theme_color_override("font_color", Color.WHITE)
		legend_label.add_theme_font_size_override("font_size", max(6, int(8 * scale)))
		tribe_row.add_child(legend_label)
	
	# 자원 범례
	var resource_title = Label.new()
	resource_title.text = "자원:"
	resource_title.add_theme_color_override("font_color", Color.WHITE)
	resource_title.add_theme_font_size_override("font_size", max(8, int(10 * scale)))
	legend_container.add_child(resource_title)
	
	var resource_colors = [Color.GOLD, Color.BROWN, Color.ORANGE, Color.PURPLE]
	var resource_names = ["🌾곡물", "🍖고기", "🥕채소", "🍇과일"]
	
	for i in range(resource_names.size()):
		var resource_row = HBoxContainer.new()
		legend_container.add_child(resource_row)
		
		var resource_dot = ColorRect.new()
		resource_dot.size = Vector2(6 * scale, 6 * scale)
		resource_dot.color = resource_colors[i]
		resource_row.add_child(resource_dot)
		
		var resource_label = Label.new()
		resource_label.text = resource_names[i]
		resource_label.add_theme_color_override("font_color", Color.WHITE)
		resource_label.add_theme_font_size_override("font_size", max(6, int(8 * scale)))
		resource_row.add_child(resource_label)