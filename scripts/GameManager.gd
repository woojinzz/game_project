extends Node2D

@onready var tilemap = $TileMap
@onready var camera = $Camera2D
@onready var stats_panel = $UI/StatsPanel

var agents = []
var resources = []
var map_width = 200  # 맵 넓이 4배 확대
var map_height = 120  # 맵 높이 4배 확대  
var agent_count = 60  # 에이전트 수 최적화 (80→60)
var resource_count = 80  # 자원 수 최적화 (120→80)

var Agent = preload("res://scripts/Agent.gd")
var GameResource = preload("res://scripts/Resource.gd")

var simulation_speed = 1.0
var total_conflicts = 0
var total_trades = 0

# 줌 관련 변수들
var current_zoom = 1.0
var min_zoom = 0.1    # 더 많이 줌아웃 가능
var max_zoom = 5.0    # 더 많이 줌인 가능
var zoom_speed = 0.15  # 더 빠른 줌 속도

# 마우스 드래그 관련 변수들
var is_dragging = false
var drag_start_pos = Vector2.ZERO
var last_mouse_pos = Vector2.ZERO

# 성능 최적화 타이머들
var stats_update_timer = 0.0
var conflicts_update_timer = 0.0
var behavior_update_timer = 0.0
var resource_events_timer = 0.0
var cleanup_timer = 0.0

# 업데이트 간격 (초)
var stats_update_interval = 0.5    # 0.5초마다
var conflicts_update_interval = 0.1  # 0.1초마다  
var behavior_update_interval = 1.0   # 1초마다
var resource_events_interval = 2.0   # 2초마다
var cleanup_interval = 5.0           # 5초마다 정리

var emergence_tracker
var observer_controls
var tribe_system
var agent_detail_panel
var minimap
var resource_event_system
var event_banner
var relationship_visualizer
var event_logger
var knowledge_system
var economy_system

func _ready():
	print("🎮 GameManager 시작...")
	
	# Initialize core systems first
	setup_tilemap()
	setup_camera()
	print("✅ 코어 시스템 초기화 완료")
	
	# Initialize basic systems
	try_initialize_systems()
	
	# Spawn game objects
	spawn_resources()
	spawn_agents()
	
	print("🎮 GameManager 초기화 완료!")

# 첫 번째 _process 함수 제거됨 (두 번째와 통합)

func handle_keyboard_zoom(event):
	# 키보드 줌 제어 (이벤트 기반)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_EQUAL, KEY_PLUS, KEY_PAGEUP:
				zoom_camera(zoom_speed * 2)
				print("🔍 줌인!")
			KEY_MINUS, KEY_PAGEDOWN:
				zoom_camera(-zoom_speed * 2)
				print("🔍 줌아웃!")

func handle_zoom_input():
	# 연속 키 입력 처리 (_process에서 호출)
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_PLUS) or Input.is_key_pressed(KEY_PAGEUP):
		zoom_camera(zoom_speed)
	elif Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_PAGEDOWN):
		zoom_camera(-zoom_speed)

func handle_zoom_scroll(event):
	# 마우스 휠 줌 제어 (개선된 감도)
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(zoom_speed * 3)  # 더 빠른 줌인
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(-zoom_speed * 3)  # 더 빠른 줌아웃

func zoom_camera(zoom_delta: float):
	var new_zoom = current_zoom + zoom_delta
	new_zoom = clamp(new_zoom, min_zoom, max_zoom)
	
	if new_zoom != current_zoom:
		current_zoom = new_zoom
		camera.zoom = Vector2(current_zoom, current_zoom)
		print("🔍 줌 변경: ", "%.2f" % current_zoom, " (범위: ", min_zoom, " ~ ", max_zoom, ")")

func handle_camera_movement():
	# 카메라 이동 (WASD 키 또는 화살표 키)
	var move_speed = 300.0 / current_zoom  # 줌에 따라 이동 속도 조정
	var movement = Vector2()
	
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= move_speed
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += move_speed
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= move_speed
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += move_speed
	
	if movement != Vector2.ZERO:
		camera.global_position += movement * get_process_delta_time()
		
		# 카메라가 맵 밖으로 나가지 않도록 제한
		var map_bounds_x = map_width * 32
		var map_bounds_y = map_height * 32
		camera.global_position.x = clamp(camera.global_position.x, 0, map_bounds_x)
		camera.global_position.y = clamp(camera.global_position.y, 0, map_bounds_y)

func handle_mouse_drag(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				# 우클릭 드래그 시작
				is_dragging = true
				drag_start_pos = event.global_position
				last_mouse_pos = event.global_position
			else:
				# 드래그 종료
				is_dragging = false
	
	elif event is InputEventMouseMotion and is_dragging:
		# 마우스 드래그 중 - 수직 움직임으로 줌 조절
		var drag_delta = event.global_position - last_mouse_pos
		var zoom_delta = -drag_delta.y * 0.01  # 위로 드래그하면 줌 인
		
		zoom_camera(zoom_delta)
		last_mouse_pos = event.global_position

func try_initialize_systems():
	# Initialize emergence tracker
	if EmergentBehaviorTracker:
		emergence_tracker = EmergentBehaviorTracker.new()
		print("✅ EmergentBehaviorTracker 초기화")
	
	# Initialize tribe system
	if TribeSystem:
		tribe_system = TribeSystem.new()
		print("✅ TribeSystem 초기화")
	
	# Initialize knowledge system
	knowledge_system = KnowledgeSystem.new()
	print("✅ KnowledgeSystem 초기화")
	
	# Initialize economy system
	economy_system = EconomySystem.new()
	print("✅ EconomySystem 초기화")
	
	# Initialize event logger first (needed by others)
	if EventLogger:
		event_logger = EventLogger.new()
		$UI.add_child(event_logger)
		print("✅ EventLogger 초기화")
	
	# Initialize agent detail panel
	if AgentDetailPanel:
		agent_detail_panel = AgentDetailPanel.new()
		$UI.add_child(agent_detail_panel)
		print("✅ AgentDetailPanel 초기화")
	
	# Initialize minimap
	if Minimap:
		minimap = Minimap.new()
		minimap.set_game_manager(self)
		$UI.add_child(minimap)
		print("✅ Minimap 초기화")
	
	# Initialize other systems
	if ResourceEventSystem:
		resource_event_system = ResourceEventSystem.new(self)
		print("✅ ResourceEventSystem 초기화")
	
	if EventBanner:
		event_banner = EventBanner.new()
		$UI.add_child(event_banner)
		print("✅ EventBanner 초기화")
	
	if RelationshipVisualizer:
		relationship_visualizer = RelationshipVisualizer.new()
		relationship_visualizer.set_game_manager(self)
		add_child(relationship_visualizer)
		print("✅ RelationshipVisualizer 초기화")

func setup_tilemap():
	var tileset = TileSet.new()
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	
	# 더 명확한 배경색 - 어두운 녹색으로 자연 환경 표현
	image.fill(Color(0.2, 0.4, 0.2))
	texture.set_image(image)
	
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.create_tile(Vector2i(0, 0))
	tileset.add_source(atlas_source, 0)
	
	tilemap.tile_set = tileset
	
	# 격자 무늬로 지형 구분감 추가
	for x in range(map_width):
		for y in range(map_height):
			tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

func setup_camera():
	var center_x = map_width * 16
	var center_y = map_height * 16
	camera.global_position = Vector2(center_x, center_y)
	
	# 초기 줌 설정 (큰 맵에 맞게 줌 아웃)
	current_zoom = 0.5  # 초기에는 줌 아웃 상태
	camera.zoom = Vector2(current_zoom, current_zoom)
	
	print("📷 카메라 초기화 - 중심: ", Vector2(center_x, center_y), ", 줌: ", current_zoom)
	print("🎮 컨트롤 안내:")
	print("   📹 줌인: 마우스휠↑ / + / PageUp")
	print("   📹 줌아웃: 마우스휠↓ / - / PageDown") 
	print("   🚶 이동: WASD 또는 화살표 키")
	print("   🖱️ 드래그 줌: 우클릭 + 드래그")
	print("   🖱️ 에이전트 선택: 좌클릭")

func spawn_resources():
	for i in range(resource_count):
		var resource = GameResource.new()
		var pos = Vector2(
			randf_range(0, map_width - 1) * 32 + 16,
			randf_range(0, map_height - 1) * 32 + 16
		)
		resource.setup(pos)
		add_child(resource)
		resources.append(resource)

func spawn_agents():
	for i in range(agent_count):
		var agent_scene = preload("res://scenes/Agent.tscn")
		var agent
		
		if agent_scene:
			agent = agent_scene.instantiate()
		else:
			agent = Agent.new()
		
		var pos = Vector2(
			randf_range(0, map_width - 1) * 32 + 16,
			randf_range(0, map_height - 1) * 32 + 16
		)
		agent.setup(pos, self)
		add_child(agent)
		agents.append(agent)
		
		# 부족에 배정
		if tribe_system:
			tribe_system.assign_agent_to_tribe(agent, i)

func get_nearest_resource(pos):
	var nearest = null
	var min_distance = INF
	
	for resource in resources:
		if not is_instance_valid(resource):
			continue
		var distance = pos.distance_to(resource.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest = resource
	
	return nearest

func get_agents_in_range(pos, range_distance):
	var nearby_agents = []
	var range_squared = range_distance * range_distance  # 제곱 거리 계산으로 최적화
	
	for agent in agents:
		if not is_instance_valid(agent):
			continue
		# 제곱 거리 비교로 sqrt 연산 생략
		if pos.distance_squared_to(agent.global_position) <= range_squared:
			nearby_agents.append(agent)
			
		# 너무 많은 에이전트가 발견되면 조기 종료 (성능 최적화)
		if nearby_agents.size() >= 10:
			break
			
	return nearby_agents

func get_agent_by_id(agent_id: int):
	# ID로 에이전트 찾기 (안전한 접근용)
	for agent in agents:
		if is_instance_valid(agent) and agent.get_instance_id() == agent_id:
			return agent
	return null

func remove_resource(resource):
	if resource in resources:
		resources.erase(resource)
	if is_instance_valid(resource):
		resource.queue_free()

func _process(delta):
	# 입력 처리 (매 프레임)
	handle_zoom_input()
	handle_camera_movement()
	
	# 기본 시뮬레이션 (매 프레임)
	update_simulation(delta)
	
	# 타이머 기반 최적화 업데이트
	update_timers_and_systems(delta)

func update_timers_and_systems(delta):
	# 통계 업데이트
	stats_update_timer += delta
	if stats_update_timer >= stats_update_interval:
		stats_update_timer = 0.0
		update_stats()
	
	# 충돌 처리 
	conflicts_update_timer += delta
	if conflicts_update_timer >= conflicts_update_interval:
		conflicts_update_timer = 0.0
		handle_conflicts()
	
	# 행동 분석
	behavior_update_timer += delta
	if behavior_update_timer >= behavior_update_interval:
		behavior_update_timer = 0.0
		track_emergent_behavior(delta)
		update_advanced_behaviors()
	
	# 자원 이벤트
	resource_events_timer += delta
	if resource_events_timer >= resource_events_interval:
		resource_events_timer = 0.0
		update_resource_events(delta)
	
	# 정리 작업
	cleanup_timer += delta
	if cleanup_timer >= cleanup_interval:
		cleanup_timer = 0.0
		cleanup_invalid_references()

func _input(event):
	# 마우스 줌 및 드래그 제어
	handle_zoom_scroll(event)
	handle_mouse_drag(event)
	
	# 키보드 줌 제어
	handle_keyboard_zoom(event)
	
	# 기존 마우스 클릭 처리
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and not is_dragging:
			handle_agent_click(event.global_position)

func _unhandled_input(event):
	# 처리되지 않은 입력 이벤트 처리
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				print("🔄 시뮬레이션 리셋")
				# 필요시 리셋 기능 추가
			KEY_SPACE:
				print("⏸️ 시뮬레이션 일시정지/재개")
				# 필요시 일시정지 기능 추가
			KEY_H:
				print_help()
			KEY_C:
				center_camera_on_agents()

func print_help():
	print("🆘 도움말:")
	print("   H: 이 도움말 표시")
	print("   C: 카메라를 에이전트들 중심으로 이동")
	print("   R: 리셋 (미구현)")
	print("   SPACE: 일시정지 (미구현)")

func center_camera_on_agents():
	if agents.size() == 0:
		return
	
	var center = Vector2.ZERO
	var valid_count = 0
	
	for agent in agents:
		if is_instance_valid(agent):
			center += agent.global_position
			valid_count += 1
	
	if valid_count > 0:
		center /= valid_count
		camera.global_position = center
		print("📹 카메라 중심 이동: ", center)

func update_simulation(delta):
	Engine.time_scale = simulation_speed
	
	for i in range(agents.size() - 1, -1, -1):
		var agent = agents[i]
		if not is_instance_valid(agent):
			# 에이전트가 무효해지기 전에 ID를 안전하게 가져오기
			var agent_id = 0
			if agent != null:
				agent_id = agent.get_instance_id()
			
			print("🗑️ 무효한 에이전트 제거 중: ", agent_id)
			
			if agent_id > 0:
				cleanup_agent_data(agent_id)
			
			agents.remove_at(i)
	
	for i in range(resources.size() - 1, -1, -1):
		if not is_instance_valid(resources[i]):
			resources.remove_at(i)

func cleanup_agent_data(agent_id: int):
	# EmergentBehaviorTracker에서 해당 에이전트 데이터 정리
	if emergence_tracker:
		emergence_tracker.cleanup_agent_data(agent_id)
	
	# 모든 에이전트의 메모리에서 해당 에이전트 제거
	for agent in agents:
		if is_instance_valid(agent):
			agent.cleanup_memory_of_agent(agent_id)

func cleanup_invalid_references():
	# 정기적으로 무효한 참조들 정리
	if emergence_tracker:
		emergence_tracker.cleanup_invalid_agent_references(self)

func update_advanced_behaviors():
	# 에이전트들의 고급 행동 업데이트
	for agent in agents:
		if is_instance_valid(agent):
			agent.practice_profession()
			agent.share_knowledge_with_nearby()
			agent.innovate()
	
	# 경제 시스템 업데이트
	if economy_system:
		var resource_counts = count_resources_by_type()
		economy_system.update_market_prices(resource_counts)
		economy_system.simulate_economic_events()

func count_resources_by_type() -> Dictionary:
	var counts = {
		"grain": 0,
		"meat": 0,
		"carrot": 0,
		"berry": 0
	}
	
	for resource in resources:
		if is_instance_valid(resource):
			var type = resource.resource_type
			if counts.has(type):
				counts[type] += 1
	
	return counts

func handle_conflicts():
	handle_deadly_conflicts()
	handle_reproduction()
	handle_resource_competition()

func handle_deadly_conflicts():
	# 더 다양하고 위험한 충돌 시스템
	for i in range(agents.size()):
		var agent = agents[i]
		if not is_instance_valid(agent) or agent.is_dead:
			continue
			
		var nearby_agents = get_agents_in_range(agent.global_position, 50)
		
		for nearby_agent in nearby_agents:
			if nearby_agent == agent or not is_instance_valid(nearby_agent) or nearby_agent.is_dead:
				continue
			
			var conflict_chance = calculate_conflict_probability(agent, nearby_agent)
			
			if randf() < conflict_chance:
				resolve_conflict(agent, nearby_agent)

func calculate_conflict_probability(agent1, agent2) -> float:
	var base_chance = 0.01  # 기본 1% 충돌 확률
	
	# 배고픔 요인
	var hunger_factor = 0.0
	if agent1.hunger > 80 and agent2.hunger > 80:
		hunger_factor = 0.15  # 둘 다 배고프면 15% 추가
	elif agent1.hunger > 60 or agent2.hunger > 60:
		hunger_factor = 0.05  # 하나라도 배고프면 5% 추가
	
	# 성격 요인
	var personality_factor = 0.0
	if agent1.personality.greed > 70 or agent2.personality.greed > 70:
		personality_factor += 0.08  # 탐욕스러우면 충돌 증가
	
	if agent1.personality.cowardice > 70 and agent2.personality.cowardice > 70:
		personality_factor -= 0.05  # 둘 다 겁쟁이면 충돌 감소
	
	# 기억 편향 요인 (안전한 접근)
	var memory_factor = 0.0
	if agent1.has_method("get_memory_bias_towards") and agent2.has_method("get_memory_bias_towards"):
		var agent1_bias = agent1.get_memory_bias_towards(agent2.get_instance_id())
		var agent2_bias = agent2.get_memory_bias_towards(agent1.get_instance_id())
		
		if agent1_bias < -0.3 or agent2_bias < -0.3:
			memory_factor = 0.12  # 나쁜 기억이 있으면 충돌 증가
	
	# 부족 관계 요인
	var tribe_factor = 0.0
	if tribe_system and not tribe_system.is_same_tribe(agent1, agent2):
		tribe_factor = 0.03  # 다른 부족이면 약간 충돌 증가
	
	# 자원 경쟁 요인
	var resource_factor = 0.0
	var nearby_resources = 0
	for resource in resources:
		if is_instance_valid(resource):
			var dist1 = agent1.global_position.distance_to(resource.global_position)
			var dist2 = agent2.global_position.distance_to(resource.global_position)
			if dist1 < 60 and dist2 < 60:
				nearby_resources += 1
	
	if nearby_resources < 2:
		resource_factor = 0.08  # 자원이 부족하면 경쟁 심화
	
	return clamp(base_chance + hunger_factor + personality_factor + memory_factor + tribe_factor + resource_factor, 0.0, 0.5)

func resolve_conflict(agent1, agent2):
	total_conflicts += 1
	
	# 충돌 강도 계산
	var agent1_strength = (agent1.health / 100.0) * (agent1.energy / 100.0) * (1.0 - agent1.personality.cowardice / 100.0)
	var agent2_strength = (agent2.health / 100.0) * (agent2.energy / 100.0) * (1.0 - agent2.personality.cowardice / 100.0)
	
	var damage_base = 15.0
	var winner = agent1 if agent1_strength > agent2_strength else agent2
	var loser = agent2 if winner == agent1 else agent1
	
	# 피해 적용
	var damage_to_loser = damage_base + randf_range(5, 15)
	var damage_to_winner = damage_base * 0.3 + randf_range(2, 8)
	
	loser.health -= damage_to_loser
	winner.health -= damage_to_winner
	
	# 에너지 소모
	agent1.energy = max(10, agent1.energy - 20)
	agent2.energy = max(10, agent2.energy - 20)
	
	# 기억 추가
	agent1.add_memory(agent1.MemoryType.CONFLICT, agent2.get_instance_id(), "폭력적 충돌")
	agent2.add_memory(agent2.MemoryType.CONFLICT, agent1.get_instance_id(), "폭력적 충돌")
	
	print("⚔️ ", agent1.tribe_name, " vs ", agent2.tribe_name, " 충돌! 승자: ", winner.tribe_name)
	
	# 충돌 시각 효과 추가
	if agent1.has_method("add_action_indicator"):
		agent1.add_action_indicator("⚔️", Color.RED)
	if agent2.has_method("add_action_indicator"):
		agent2.add_action_indicator("⚔️", Color.RED)
	
	# 승자에게 특별 효과
	if winner.has_method("add_action_indicator"):
		winner.call_deferred("add_action_indicator", "💪", Color.GOLD)
	
	# 이벤트 로그에 기록
	if event_logger:
		event_logger.log_conflict(agent1.tribe_name, agent2.tribe_name, winner.tribe_name)

func handle_reproduction():
	# 번식 처리
	for i in range(agents.size()):
		var agent = agents[i]
		if not is_instance_valid(agent) or agent.is_dead or not agent.can_reproduce():
			continue
		
		var nearby_agents = get_agents_in_range(agent.global_position, 40)
		
		for nearby_agent in nearby_agents:
			if nearby_agent == agent or not is_instance_valid(nearby_agent) or nearby_agent.is_dead:
				continue
			
			if not nearby_agent.can_reproduce():
				continue
			
			# 번식 시도
			var reproduction_result = agent.attempt_reproduction(nearby_agent)
			if reproduction_result:
				spawn_child_agent(reproduction_result)
				break  # 한 번에 하나씩만

func spawn_child_agent(reproduction_data):
	var parent1 = reproduction_data.parent1
	var parent2 = reproduction_data.parent2
	var child_pos = reproduction_data.position
	
	# 새 에이전트 생성
	var child_scene = preload("res://scenes/Agent.tscn")
	var child
	
	if child_scene:
		child = child_scene.instantiate()
	else:
		child = Agent.new()
	
	child.setup(child_pos, self)
	
	# 부모로부터 성격 유전 (평균 + 돌연변이)
	inherit_personality(child, parent1, parent2)
	
	# 부족 배정
	if tribe_system:
		# 부모 중 하나의 부족을 랜덤으로 선택
		var parent_tribe = parent1.tribe if randf() < 0.5 else parent2.tribe
		tribe_system.assign_agent_to_specific_tribe(child, parent_tribe)
	
	add_child(child)
	agents.append(child)
	
	print("👶 새 에이전트 탄생! 부모: ", parent1.tribe_name, " + ", parent2.tribe_name)
	
	# 번식 성공 시각 효과
	if parent1.has_method("add_action_indicator"):
		parent1.add_action_indicator("💕", Color.PINK)
	if parent2.has_method("add_action_indicator"):
		parent2.add_action_indicator("💕", Color.PINK)
	
	# 신생아 출현 효과
	if child.has_method("add_action_indicator"):
		child.call_deferred("add_action_indicator", "👶", Color.LIGHT_GREEN)
	
	# 이벤트 로그에 기록
	if event_logger:
		event_logger.log_agent_birth(child.tribe_name, parent1.tribe_name, parent2.tribe_name)

func inherit_personality(child, parent1, parent2):
	# 부모 성격의 평균값
	var avg_greed = (parent1.personality.greed + parent2.personality.greed) / 2
	var avg_sociability = (parent1.personality.sociability + parent2.personality.sociability) / 2
	var avg_cowardice = (parent1.personality.cowardice + parent2.personality.cowardice) / 2
	var avg_curiosity = (parent1.personality.curiosity + parent2.personality.curiosity) / 2
	var avg_vengefulness = (parent1.personality.vengefulness + parent2.personality.vengefulness) / 2
	
	# 돌연변이 (±10 범위)
	child.personality.greed = clamp(avg_greed + randf_range(-10, 10), 0, 100)
	child.personality.sociability = clamp(avg_sociability + randf_range(-10, 10), 0, 100)
	child.personality.cowardice = clamp(avg_cowardice + randf_range(-10, 10), 0, 100)
	child.personality.curiosity = clamp(avg_curiosity + randf_range(-10, 10), 0, 100)
	child.personality.vengefulness = clamp(avg_vengefulness + randf_range(-10, 10), 0, 100)
	
	print("🧬 유전된 성격 - 탐욕:", int(child.personality.greed), " 친화력:", int(child.personality.sociability))

func handle_resource_competition():
	# 자원 주변에서의 경쟁 처리
	for resource in resources:
		if not is_instance_valid(resource):
			continue
		
		var competing_agents = []
		for agent in agents:
			if is_instance_valid(agent) and not agent.is_dead:
				if agent.global_position.distance_to(resource.global_position) < 30:
					competing_agents.append(agent)
		
		if competing_agents.size() > 2:
			# 경쟁이 치열한 상황
			for i in range(competing_agents.size()):
				for j in range(i + 1, competing_agents.size()):
					var agent1 = competing_agents[i]
					var agent2 = competing_agents[j]
					
					if randf() < 0.1:  # 10% 확률로 자원 경쟁 충돌
						agent1.add_memory(agent1.MemoryType.RESOURCE_LOSS, agent2.get_instance_id(), "자원 경쟁")
						agent2.add_memory(agent2.MemoryType.RESOURCE_LOSS, agent1.get_instance_id(), "자원 경쟁")

func handle_agent_death(dead_agent):
	if not dead_agent.is_dead:
		return
	
	# 죽은 에이전트 처리
	print("🏥 사망 처리: ", dead_agent.tribe_name)
	
	# 5초 후 제거 (시체가 잠시 남아있음)
	await get_tree().create_timer(5.0).timeout
	
	if is_instance_valid(dead_agent):
		agents.erase(dead_agent)
		dead_agent.queue_free()
		
	print("🗑️ 시체 제거 완료. 현재 에이전트 수: ", agents.size())

func record_trade():
	total_trades += 1

func track_emergent_behavior(delta):
	if emergence_tracker:
		for agent in agents:
			if is_instance_valid(agent):
				emergence_tracker.track_agent_behavior(agent, delta)

func update_stats():
	if stats_panel:
		stats_panel.update_stats(agents, resources)
		
		# 창발 현상 정보도 전달
		if emergence_tracker:
			var emergence_summary = emergence_tracker.get_emergence_summary()
			stats_panel.update_emergence_info(emergence_summary)
		
		# 부족 통계 업데이트
		stats_panel.update_tribe_stats(self)

func update_resource_events(delta):
	if resource_event_system:
		resource_event_system.update(delta)
		
		# 이벤트 배너 업데이트
		if event_banner:
			var event_info = resource_event_system.get_current_event_info()
			if event_info.get("active", false):
				event_banner.show_event(event_info)
			else:
				event_banner.hide_banner()

func reset_simulation():
	print("🔄 시뮬레이션 초기화 중...")
	
	# 기존 에이전트와 자원 제거
	for agent in agents:
		if is_instance_valid(agent):
			agent.queue_free()
	for resource in resources:
		if is_instance_valid(resource):
			resource.queue_free()
	
	agents.clear()
	resources.clear()
	
	# 통계 초기화
	total_conflicts = 0
	total_trades = 0
	
	if stats_panel:
		stats_panel.reset_stats()
	
	if emergence_tracker:
		emergence_tracker.reset()
		
	if tribe_system:
		tribe_system.reset()
		
	if resource_event_system:
		resource_event_system.reset()
	
	if relationship_visualizer:
		relationship_visualizer.reset()
	
	# 새로운 시뮬레이션 시작
	spawn_resources()
	spawn_agents()
	
	print("✅ 시뮬레이션이 초기화되었습니다")

func handle_agent_click(click_pos: Vector2):
	# 카메라 변환 고려
	var world_pos = click_pos
	if camera:
		# 카메라 오프셋과 줌 고려
		world_pos = (click_pos - get_viewport().size / 2) * camera.zoom + camera.global_position
	
	var closest_agent = null
	var min_distance = 50.0  # 클릭 감지 범위
	
	for agent in agents:
		if not is_instance_valid(agent):
			continue
		
		var distance = agent.global_position.distance_to(world_pos)
		if distance < min_distance:
			min_distance = distance
			closest_agent = agent
	
	if closest_agent and agent_detail_panel:
		agent_detail_panel.select_agent(closest_agent)
		print("🔍 에이전트 선택: ", closest_agent.tribe_name, " (ID: ", closest_agent.get_instance_id(), ")")
		
		# 선택된 에이전트의 관계선만 하이라이트 (관계선 표시가 활성화된 경우)
		if relationship_visualizer:
			relationship_visualizer.highlight_agent_relationships(closest_agent)
