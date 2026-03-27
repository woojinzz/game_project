extends CharacterBody2D

var hunger = 50.0
var energy = 50.0
var trust = 50.0
var speed = 50.0
var game_manager

var move_velocity = Vector2.ZERO
var target_position = Vector2.ZERO
var current_state = "wandering"
var state_timer = 0.0
var decision_timer = 0.0
var decision_interval = 2.0  # 결정 간격을 2배 늘려서 성능 최적화

enum ActionType {
	WANDER,
	SEEK_FOOD,
	REST,
	TRADE,
	FLEE
}

var current_action = ActionType.WANDER
var target_resource = null
var target_agent = null

var utility_ai

# 부족 시스템 변수
var tribe = null
var tribe_name = ""
var tribe_color = Color.BLUE

# 성격 시스템 변수 (0~100)
var personality = {
	"greed": 50,        # 탐욕: 자원 독점 성향
	"sociability": 50,  # 친화력: 사교성과 협력 성향
	"cowardice": 50,    # 겁쟁이: 위험 회피 성향
	"curiosity": 50,    # 호기심: 탐험과 새로운 것 추구
	"vengefulness": 50  # 복수심: 배신에 대한 기억과 보복
}

# 단기 기억 시스템
var short_term_memory = []
var max_memory_count = 10

enum MemoryType {
	BETRAYAL,      # 배신당함
	KINDNESS,      # 친절함을 받음
	CONFLICT,      # 충돌 발생
	COOPERATION,   # 협력 성공
	RESOURCE_LOSS, # 자원 빼앗김
	TRADE_SUCCESS  # 거래 성공
}

# 장기 목표 시스템
var long_term_goals = []
var max_goals = 3
var goal_update_timer = 0.0
var goal_update_interval = 30.0  # 30초마다 목표 재평가

enum GoalType {
	TERRITORY_CONTROL,    # 특정 영역 지배
	RESOURCE_MONOPOLY,    # 자원 독점
	ALLIANCE_BUILDING,    # 동맹 구축
	EXPLORATION,          # 미탐험 영역 탐사
	REVENGE              # 특정 에이전트에게 복수
}

# 생존 시스템
var max_health = 100.0
var health = 100.0
var age = 0.0
var max_age = 900.0  # 15분 생존 (3배 연장)
var reproduction_cooldown = 0.0
var reproduction_interval = 120.0  # 2분마다 번식 가능
var is_dead = false

# 개인 특성과 전문성
var profession = ""  # 직업/전문분야
var specialization_level = 0.0  # 전문성 수준
var innovation_chance = 0.01  # 혁신 확률
var teaching_skill = 0.0  # 가르치는 능력
var learning_speed = 1.0  # 학습 속도

# 애니메이션 관련 변수
var last_health_warning_time = 0.0
var game_time = 0.0

func setup(pos, manager):
	global_position = pos
	game_manager = manager
	utility_ai = UtilityAI.new()
	
	hunger = randf_range(10, 40)  # 시작 배고픔 낮춤 (30-70 → 10-40)
	energy = randf_range(50, 80)  # 시작 에너지 높임 (30-70 → 50-80)
	trust = randf_range(30, 70)
	
	generate_personality()
	develop_specialization()
	create_visual()
	setup_collision()

func generate_personality():
	# 각 성격 요소를 랜덤하게 생성 (0~100)
	personality.greed = randf_range(0, 100)
	personality.sociability = randf_range(0, 100)
	personality.cowardice = randf_range(0, 100)
	personality.curiosity = randf_range(0, 100)
	personality.vengefulness = randf_range(0, 100)
	
	print("🧠 새 에이전트 성격 생성:")
	print("   탐욕: ", int(personality.greed))
	print("   친화력: ", int(personality.sociability))
	print("   겁쟁이: ", int(personality.cowardice))
	print("   호기심: ", int(personality.curiosity))
	print("   복수심: ", int(personality.vengefulness))

func develop_specialization():
	# 성격에 따른 전문 분야 선택
	var professions = ["농부", "사냥꾼", "장인", "의사", "건축가", "상인", "교사", "전사"]
	var weights = []
	
	# 성격에 따른 직업 선호도 계산
	weights.append(personality.greed * 0.5 + (100 - personality.cowardice) * 0.3)  # 농부
	weights.append((100 - personality.cowardice) * 0.7 + personality.vengefulness * 0.3)  # 사냥꾼
	weights.append(personality.curiosity * 0.6 + personality.greed * 0.2)  # 장인
	weights.append(personality.sociability * 0.5 + personality.curiosity * 0.4)  # 의사
	weights.append(personality.curiosity * 0.5 + (100 - personality.cowardice) * 0.3)  # 건축가
	weights.append(personality.greed * 0.6 + personality.sociability * 0.4)  # 상인
	weights.append(personality.sociability * 0.8 + personality.curiosity * 0.2)  # 교사
	weights.append(personality.vengefulness * 0.5 + (100 - personality.cowardice) * 0.5)  # 전사
	
	# 가중치 기반 직업 선택
	var max_weight = 0.0
	var chosen_profession = 0
	
	for i in range(weights.size()):
		if weights[i] > max_weight:
			max_weight = weights[i]
			chosen_profession = i
	
	profession = professions[chosen_profession]
	specialization_level = randf_range(0, 20)  # 초기 전문성
	learning_speed = randf_range(0.8, 1.5)
	teaching_skill = personality.sociability / 100.0
	innovation_chance = personality.curiosity / 10000.0  # 호기심이 높을수록 혁신적
	
	print("🔧 ", tribe_name, " 전문직: ", profession, " (전문성: ", int(specialization_level), ")")

func get_personality_description() -> String:
	var traits = []
	
	if personality.greed > 70:
		traits.append("탐욕스러운")
	elif personality.greed < 30:
		traits.append("관대한")
	
	if personality.sociability > 70:
		traits.append("사교적인")
	elif personality.sociability < 30:
		traits.append("내성적인")
	
	if personality.cowardice > 70:
		traits.append("겁쟁이")
	elif personality.cowardice < 30:
		traits.append("용감한")
	
	if personality.curiosity > 70:
		traits.append("호기심많은")
	elif personality.curiosity < 30:
		traits.append("보수적인")
	
	if personality.vengefulness > 70:
		traits.append("복수심강한")
	elif personality.vengefulness < 30:
		traits.append("관용적인")
	
	return " ".join(traits) if traits.size() > 0 else "평범한"

# 단기 기억 관리 함수들
func add_memory(memory_type: MemoryType, other_agent_id: int, details: String = ""):
	# other_agent_id 유효성 검사
	if other_agent_id <= 0:
		return
		
	var memory = {
		"type": memory_type,
		"other_agent": other_agent_id,
		"details": details,
		"timestamp": Time.get_ticks_msec(),
		"intensity": calculate_memory_intensity(memory_type)
	}
	
	short_term_memory.append(memory)
	
	# 최대 기억 개수 초과 시 가장 오래된 기억 삭제
	if short_term_memory.size() > max_memory_count:
		short_term_memory.pop_front()
	
	# 기억에 따른 신뢰도 조정 (안전하게)
	if game_manager and game_manager.has_method("get_agent_by_id"):
		var other_agent = game_manager.get_agent_by_id(other_agent_id)
		if is_instance_valid(other_agent):
			adjust_trust_by_memory(memory_type, other_agent_id)
	
	print("💭 ", tribe_name, " 기억 추가: ", get_memory_description(memory_type), " (상대: ", other_agent_id, ")")

func calculate_memory_intensity(memory_type: MemoryType) -> float:
	# 성격에 따른 기억 강도 계산
	match memory_type:
		MemoryType.BETRAYAL:
			return 0.5 + (personality.vengefulness / 200.0)  # 복수심이 높을수록 더 강하게 기억
		MemoryType.KINDNESS:
			return 0.3 + (personality.sociability / 300.0)   # 친화력이 높을수록 더 감사하게 기억
		MemoryType.CONFLICT:
			return 0.4 + (personality.cowardice / 250.0)     # 겁쟁이일수록 더 무섭게 기억
		MemoryType.COOPERATION:
			return 0.3 + (personality.sociability / 300.0)   # 사교적일수록 더 긍정적으로 기억
		MemoryType.RESOURCE_LOSS:
			return 0.4 + (personality.greed / 250.0)         # 탐욕스러울수록 더 분노하게 기억
		MemoryType.TRADE_SUCCESS:
			return 0.2 + (personality.greed / 500.0)         # 탐욕과 관계없이 약한 긍정적 기억
		_:
			return 0.3

func adjust_trust_by_memory(memory_type: MemoryType, other_agent_id: int):
	if not game_manager or not game_manager.emergence_tracker:
		return
	
	var my_id = get_instance_id()
	if my_id <= 0 or other_agent_id <= 0:
		return
	
	var social_networks = game_manager.emergence_tracker.social_networks
	if not social_networks.has(my_id):
		return
	
	var my_network = social_networks.get(my_id, {})
	if not my_network.has("trust_relationships"):
		return
		
	var trust_relationships = my_network.get("trust_relationships", {})
	
	var current_trust = trust_relationships.get(other_agent_id, 0.0)
	var trust_change = 0.0
	
	match memory_type:
		MemoryType.BETRAYAL:
			trust_change = -15.0 - (personality.vengefulness / 10.0)  # -15~-25
		MemoryType.KINDNESS:
			trust_change = 10.0 + (personality.sociability / 20.0)    # +10~+15
		MemoryType.CONFLICT:
			trust_change = -8.0 - (personality.cowardice / 20.0)      # -8~-13
		MemoryType.COOPERATION:
			trust_change = 8.0 + (personality.sociability / 25.0)     # +8~+12
		MemoryType.RESOURCE_LOSS:
			trust_change = -12.0 - (personality.greed / 15.0)         # -12~-18.7
		MemoryType.TRADE_SUCCESS:
			trust_change = 5.0 + (personality.sociability / 50.0)     # +5~+7
	
	trust_relationships[other_agent_id] = clamp(current_trust + trust_change, -100, 100)
	
	print("🤝 ", tribe_name, "의 신뢰도 변화: ", other_agent_id, " → ", int(trust_change), " (현재: ", int(trust_relationships[other_agent_id]), ")")

func get_memory_description(memory_type: MemoryType) -> String:
	match memory_type:
		MemoryType.BETRAYAL:
			return "배신당함"
		MemoryType.KINDNESS:
			return "친절함을 받음"
		MemoryType.CONFLICT:
			return "충돌 발생"
		MemoryType.COOPERATION:
			return "협력 성공"
		MemoryType.RESOURCE_LOSS:
			return "자원을 빼앗김"
		MemoryType.TRADE_SUCCESS:
			return "거래 성공"
		_:
			return "알 수 없는 기억"

func get_memories_about_agent(agent_id: int) -> Array:
	var memories = []
	for memory in short_term_memory:
		# 안전한 딕셔너리 접근
		if memory.has("other_agent"):
			if memory.other_agent == agent_id:
				memories.append(memory)
	return memories

func cleanup_memory_of_agent(agent_id: int):
	# 단기 기억에서 해당 에이전트와 관련된 모든 기억 제거
	for i in range(short_term_memory.size() - 1, -1, -1):
		var memory = short_term_memory[i]
		if memory.has("other_agent") and memory.other_agent == agent_id:
			short_term_memory.remove_at(i)

func has_negative_memory_about(agent_id: int) -> bool:
	for memory in short_term_memory:
		# 안전한 딕셔너리 접근
		if memory.has("other_agent") and memory.has("type"):
			if memory.other_agent == agent_id:
				if memory.type in [MemoryType.BETRAYAL, MemoryType.CONFLICT, MemoryType.RESOURCE_LOSS]:
					return true
	return false

func get_memory_bias_towards(agent_id: int) -> float:
	# 특정 에이전트에 대한 기억 기반 편향 (-1.0 ~ 1.0)
	var positive_score = 0.0
	var negative_score = 0.0
	
	for memory in short_term_memory:
		# 안전한 딕셔너리 접근
		if memory.has("other_agent") and memory.has("type") and memory.has("intensity"):
			if memory.other_agent == agent_id:
				match memory.type:
					MemoryType.KINDNESS, MemoryType.COOPERATION, MemoryType.TRADE_SUCCESS:
						positive_score += memory.intensity
					MemoryType.BETRAYAL, MemoryType.CONFLICT, MemoryType.RESOURCE_LOSS:
						negative_score += memory.intensity
	
	var total_score = positive_score + negative_score
	if total_score == 0:
		return 0.0
	
	return (positive_score - negative_score) / total_score

# 장기 목표 관리 함수들
func update_long_term_goals(delta):
	goal_update_timer += delta
	if goal_update_timer >= goal_update_interval:
		goal_update_timer = 0.0
		evaluate_and_update_goals()

func evaluate_and_update_goals():
	# 현재 상황과 성격에 따라 목표 재평가
	var potential_goals = generate_potential_goals()
	
	# 기존 목표 중 완료된 것이나 우선순위가 낮아진 것 제거
	long_term_goals = filter_active_goals()
	
	# 새로운 목표 추가 (최대 3개까지)
	for goal in potential_goals:
		if long_term_goals.size() >= max_goals:
			break
		
		if not has_similar_goal(goal):
			long_term_goals.append(goal)
			print("🎯 ", tribe_name, " 새 목표: ", get_goal_description(goal))

func generate_potential_goals() -> Array:
	var goals = []
	
	# 성격에 따른 목표 생성
	if personality.greed > 60:
		goals.append(create_goal(GoalType.RESOURCE_MONOPOLY, "자원 독점"))
	
	if personality.sociability > 60:
		goals.append(create_goal(GoalType.ALLIANCE_BUILDING, "동맹 구축"))
	
	if personality.curiosity > 60:
		goals.append(create_goal(GoalType.EXPLORATION, "미지 영역 탐사"))
	
	if personality.vengefulness > 70:
		# 복수심이 높고 배신 기억이 있으면 복수 목표 생성
		for memory in short_term_memory:
			if memory.type == MemoryType.BETRAYAL:
				goals.append(create_goal(GoalType.REVENGE, "복수", memory.other_agent))
				break
	
	# 상황에 따른 목표
	if is_in_resource_scarce_area():
		goals.append(create_goal(GoalType.TERRITORY_CONTROL, "영역 확보"))
	
	return goals

func create_goal(type: GoalType, description: String, target: int = -1) -> Dictionary:
	return {
		"type": type,
		"description": description,
		"target": target,
		"priority": calculate_goal_priority(type),
		"created_time": Time.get_ticks_msec(),
		"progress": 0.0
	}

func calculate_goal_priority(type: GoalType) -> float:
	# 성격과 현재 상황에 따른 목표 우선순위 계산
	match type:
		GoalType.RESOURCE_MONOPOLY:
			return (personality.greed / 100.0) * (1.0 + (hunger / 200.0))
		GoalType.ALLIANCE_BUILDING:
			return (personality.sociability / 100.0) * (1.0 - (trust / 200.0))
		GoalType.EXPLORATION:
			return (personality.curiosity / 100.0) * (1.0 + (energy / 200.0))
		GoalType.REVENGE:
			return (personality.vengefulness / 100.0) * 1.5  # 복수는 높은 우선순위
		GoalType.TERRITORY_CONTROL:
			return 0.6 + (personality.greed / 200.0)
		_:
			return 0.5

func has_similar_goal(new_goal: Dictionary) -> bool:
	for goal in long_term_goals:
		if goal.type == new_goal.type:
			if new_goal.type == GoalType.REVENGE:
				return goal.target == new_goal.target
			else:
				return true
	return false

func filter_active_goals() -> Array:
	var active_goals = []
	for goal in long_term_goals:
		if is_goal_still_relevant(goal):
			active_goals.append(goal)
		else:
			print("🗑️ ", tribe_name, " 목표 포기: ", goal.description)
	return active_goals

func is_goal_still_relevant(goal: Dictionary) -> bool:
	match goal.type:
		GoalType.REVENGE:
			# 복수 대상이 여전히 존재하고, 복수심이 충분한지 확인
			if goal.target != -1 and personality.vengefulness > 30:
				return has_negative_memory_about(goal.target)
			return false
		GoalType.ALLIANCE_BUILDING:
			# 사교성이 여전히 높은지 확인
			return personality.sociability > 40
		GoalType.RESOURCE_MONOPOLY:
			# 탐욕이 여전히 높은지 확인
			return personality.greed > 40
		GoalType.EXPLORATION:
			# 호기심이 여전히 높고 에너지가 충분한지 확인
			return personality.curiosity > 40 and energy > 30
		GoalType.TERRITORY_CONTROL:
			# 기본적으로 항상 관련성 있음
			return true
		_:
			return true

func is_in_resource_scarce_area() -> bool:
	if not game_manager:
		return false
	
	var nearby_resources = 0
	var scan_radius = 100.0
	
	for resource in game_manager.resources:
		if is_instance_valid(resource):
			if global_position.distance_to(resource.global_position) <= scan_radius:
				nearby_resources += 1
	
	return nearby_resources < 2  # 주변에 자원이 2개 미만이면 부족한 지역

func get_goal_description(goal: Dictionary) -> String:
	var desc = goal.description
	if goal.type == GoalType.REVENGE and goal.target != -1:
		desc += " (대상: " + str(goal.target) + ")"
	return desc

func get_current_primary_goal() -> Dictionary:
	if long_term_goals.size() == 0:
		return {}
	
	# 우선순위가 가장 높은 목표 반환
	var primary_goal = long_term_goals[0]
	for goal in long_term_goals:
		if goal.priority > primary_goal.priority:
			primary_goal = goal
	
	return primary_goal

func is_pursuing_goal(goal_type: GoalType) -> bool:
	for goal in long_term_goals:
		if goal.type == goal_type:
			return true
	return false

func create_visual():
	create_pixel_art_agent()

func create_pixel_art_agent():
	# 도트 그래픽 컨테이너
	var pixel_container = Node2D.new()
	pixel_container.name = "PixelArt"
	add_child(pixel_container)
	
	# 16x16 도트 에이전트 생성
	var pixel_size = 0.8  # 각 픽셀당 0.8x0.8 크기 (훨씬 더 작게)
	var agent_pixels = get_agent_pixel_pattern()
	
	for y in range(agent_pixels.size()):
		for x in range(agent_pixels[y].size()):
			var pixel_color = agent_pixels[y][x]
			if pixel_color != Color.TRANSPARENT:
				var pixel = ColorRect.new()
				pixel.size = Vector2(pixel_size, pixel_size)
				pixel.position = Vector2(
					(x - 8) * pixel_size,  # 중앙 정렬
					(y - 8) * pixel_size
				)
				pixel.color = pixel_color
				pixel_container.add_child(pixel)
	
	# 상태 아이콘 (작고 깔끔하게)
	var state_icon = Label.new()
	state_icon.name = "StateIcon"
	state_icon.text = get_state_emoji()
	state_icon.position = Vector2(-6, -20)
	state_icon.add_theme_font_size_override("font_size", 8)
	add_child(state_icon)
	
	# 체력바 (작은 픽셀 스타일)
	create_pixel_health_bar()

func get_agent_pixel_pattern() -> Array:
	# 16x16 에이전트 도트 패턴
	var base_color = tribe_color if tribe_color != Color.BLUE else Color.BLUE
	var dark_color = base_color.darkened(0.3)
	var light_color = base_color.lightened(0.2)
	var skin_color = Color(0.9, 0.8, 0.7)  # 살색
	var eye_color = Color.BLACK
	var t = Color.TRANSPARENT
	
	return [
		[t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t],
		[t,t,t,t,t,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,t,t,t,t,t],
		[t,t,t,t,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,t,t,t,t],
		[t,t,t,skin_color,skin_color,eye_color,skin_color,skin_color,skin_color,skin_color,eye_color,skin_color,skin_color,t,t,t],
		[t,t,skin_color,skin_color,skin_color,skin_color,skin_color,eye_color,eye_color,skin_color,skin_color,skin_color,skin_color,skin_color,t,t],
		[t,t,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,skin_color,t,t],
		[t,t,t,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,t,t,t],
		[t,t,base_color,base_color,light_color,light_color,base_color,base_color,base_color,base_color,light_color,light_color,base_color,base_color,t,t],
		[t,t,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,t,t],
		[t,t,base_color,base_color,base_color,dark_color,dark_color,base_color,base_color,dark_color,dark_color,base_color,base_color,base_color,t,t],
		[t,t,t,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,base_color,t,t,t],
		[t,t,t,t,skin_color,skin_color,base_color,base_color,base_color,base_color,skin_color,skin_color,t,t,t,t],
		[t,t,t,t,skin_color,skin_color,base_color,base_color,base_color,base_color,skin_color,skin_color,t,t,t,t],
		[t,t,t,t,dark_color,dark_color,dark_color,t,t,dark_color,dark_color,dark_color,t,t,t,t],
		[t,t,t,dark_color,dark_color,dark_color,t,t,t,t,dark_color,dark_color,dark_color,t,t,t],
		[t,t,t,t,t,t,t,t,t,t,t,t,t,t,t,t]
	]

func create_pixel_health_bar():
	var health_bar_container = Node2D.new()
	health_bar_container.name = "HealthBar"
	health_bar_container.position = Vector2(-8, -18)
	add_child(health_bar_container)
	
	# 16픽셀 너비의 체력바
	for i in range(16):
		var health_pixel = ColorRect.new()
		health_pixel.name = "HealthPixel" + str(i)
		health_pixel.size = Vector2(1, 2)
		health_pixel.position = Vector2(i, 0)
		health_bar_container.add_child(health_pixel)
	
	update_health_bar()

func update_health_bar():
	var health_bar = get_node_or_null("HealthBar")
	if not health_bar:
		return
	
	var health_percentage = health / max_health
	var visible_pixels = int(health_percentage * 16)
	
	for i in range(16):
		var pixel = health_bar.get_node_or_null("HealthPixel" + str(i))
		if pixel:
			if i < visible_pixels:
				if health_percentage > 0.6:
					pixel.color = Color.GREEN
				elif health_percentage > 0.3:
					pixel.color = Color.YELLOW
				else:
					pixel.color = Color.RED
			else:
				pixel.color = Color(0.3, 0.3, 0.3)  # 어두운 회색

func get_state_emoji() -> String:
	match current_action:
		ActionType.WANDER:
			return "👣"
		ActionType.SEEK_FOOD:
			return "🍎"
		ActionType.REST:
			return "💤"
		ActionType.TRADE:
			return "💰"
		ActionType.FLEE:
			return "💨"
		_:
			return "❓"

func setup_collision():
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	collision_shape.shape = shape
	add_child(collision_shape)

func _ready():
	set_random_target()

func _physics_process(delta):
	game_time += delta
	update_stats(delta)
	update_long_term_goals(delta)
	
	decision_timer += delta
	if decision_timer >= decision_interval:
		decision_timer = 0.0
		make_decision()
	
	execute_action(delta)
	move_towards_target(delta)

func update_stats(delta):
	# 기존 스탯 업데이트 (생존율 향상)
	hunger = min(100, hunger + delta * 0.8)  # 배고픔 증가율 대폭 감소 (2→0.8)
	energy = max(0, energy - delta * 0.3)   # 에너지 소모율 더 감소 (0.5→0.3)
	
	if current_action == ActionType.REST:
		energy = min(100, energy + delta * 10)
		# 휴식 중 특별 효과
		if randf() < 0.05:  # 5% 확률로 휴식 표시
			add_action_indicator("💤", Color.LIGHT_BLUE)
	
	# 신뢰도 시스템 개선 - 더 다양한 회복/하락 조건
	if hunger > 80:
		trust = max(0, trust - delta * 2)
	elif hunger < 20:
		trust = min(100, trust + delta * 1)
	
	# 친화력 성격에 따른 자연 신뢰도 회복
	if personality.sociability > 70:
		trust = min(100, trust + delta * 0.5)
	
	# 건강 상태 체크 및 경고 효과
	if health < 30 and game_time - last_health_warning_time > 5.0:
		add_health_warning_effect()
		last_health_warning_time = game_time
	
	# 생존 시스템 업데이트
	age += delta
	reproduction_cooldown = max(0, reproduction_cooldown - delta)
	
	# 건강도 관리 (더 관대하게)
	if hunger > 95:
		health -= delta * 3  # 굶주림으로 체력 감소 (8→3)
	elif hunger > 85:
		health -= delta * 1  # 약간의 체력 감소 (3→1)
	else:
		health = min(max_health, health + delta * 3)  # 체력 회복 향상 (2→3)
	
	if energy < 5:
		health -= delta * 2  # 에너지 부족으로 체력 감소 (5→2, 임계값 10→5)
	
	# 나이로 인한 자연 체력 감소
	if age > max_age * 0.8:
		health -= delta * (age / max_age) * 3
	
	# 죽음 체크
	check_death()

func check_death():
	if is_dead:
		return
	
	var death_chance = 0.0
	
	# 체력 0 = 즉사
	if health <= 0:
		death_chance = 1.0
	
	# 노화로 인한 죽음
	elif age >= max_age:
		death_chance = 0.8
	
	# 극심한 굶주림 + 체력 부족 (더 관대하게)
	elif hunger > 98 and health < 10:
		death_chance = 0.1  # 30% → 10%
	
	# 매우 나이 많고 체력 부족 (더 관대하게)
	elif age > max_age * 0.95 and health < 20:
		death_chance = 0.05 + (age - max_age * 0.95) / (max_age * 0.05) * 0.5
	
	if randf() < death_chance:
		die()

func die():
	if is_dead:
		return
	
	is_dead = true
	print("💀 ", tribe_name, " 에이전트 사망 (나이: ", int(age), ", 체력: ", int(health), ")")
	
	# 이벤트 로그에 기록
	if game_manager and game_manager.event_logger:
		var cause = "자연사"
		if health <= 0 and hunger > 90:
			cause = "굶주림"
		elif health <= 0:
			cause = "체력 고갈"
		elif age >= max_age:
			cause = "노화"
		game_manager.event_logger.log_agent_death(tribe_name, cause, int(age))
	
	# 사망 애니메이션 효과
	play_death_animation()
	
	# 게임 매니저에 사망 알림
	if game_manager and game_manager.has_method("handle_agent_death"):
		game_manager.handle_agent_death(self)

func play_death_animation():
	# 사망 이펙트 - 회색으로 변하면서 투명해짐
	var death_icon = get_node_or_null("StateIcon")
	if death_icon:
		death_icon.text = "💀"
	
	# 트윈 애니메이션
	var tween = create_tween()
	tween.parallel().tween_property(self, "modulate", Color.GRAY, 1.0)
	tween.parallel().tween_property(self, "modulate:a", 0.5, 2.0)
	
	# 픽셀 아트도 어둡게
	var pixel_art = get_node_or_null("PixelArt")
	if pixel_art:
		tween.parallel().tween_property(pixel_art, "modulate", Color(0.5, 0.5, 0.5), 1.5)

func can_reproduce() -> bool:
	if is_dead or health < 40 or hunger > 80:  # 번식 조건 완화 (health 60→40, hunger 60→80)
		return false
	
	if reproduction_cooldown > 0 or age < 20:  # 번식 가능 나이 낮춤 (30→20)
		return false
	
	# 사교적이고 건강한 에이전트가 번식 확률 높음
	var base_chance = 0.1
	var personality_bonus = (personality.sociability / 100.0) * 0.3
	var health_bonus = (health / 100.0) * 0.2
	
	return randf() < (base_chance + personality_bonus + health_bonus)

func attempt_reproduction(partner):
	if not can_reproduce() or not partner.can_reproduce():
		return null
	
	if global_position.distance_to(partner.global_position) > 30:
		return null
	
	# 번식 성공
	reproduction_cooldown = reproduction_interval
	partner.reproduction_cooldown = reproduction_interval
	
	# 기억 추가
	add_memory(MemoryType.COOPERATION, partner.get_instance_id(), "번식 성공")
	partner.add_memory(MemoryType.COOPERATION, get_instance_id(), "번식 성공")
	
	print("👶 ", tribe_name, " ↔ ", partner.tribe_name, " 번식 성공!")
	
	# 이벤트 로그에 기록
	if game_manager and game_manager.event_logger:
		game_manager.event_logger.log_reproduction_attempt(tribe_name, partner.tribe_name, true)
	
	# 새 에이전트 생성을 위한 정보 반환
	return {
		"parent1": self,
		"parent2": partner,
		"position": (global_position + partner.global_position) / 2
	}

func make_decision():
	var utilities = calculate_utilities()
	var best_action = ActionType.WANDER
	var best_utility = 0.0
	
	for action in utilities:
		if utilities[action] > best_utility:
			best_utility = utilities[action]
			best_action = action
	
	if best_action != current_action:
		current_action = best_action
		setup_action()

func calculate_utilities():
	var utilities = {}
	
	# 현재 주요 목표와 기억 편향 가져오기
	var primary_goal = get_current_primary_goal()
	var memory_bias = 0.0
	
	# 근처 에이전트에 대한 기억 편향 계산
	var nearby_agents = []
	if game_manager:
		nearby_agents = game_manager.get_agents_in_range(global_position, 60)
	
	for nearby_agent in nearby_agents:
		if is_instance_valid(nearby_agent) and nearby_agent != self:
			var agent_id = nearby_agent.get_instance_id()
			var bias = get_memory_bias_towards(agent_id)
			memory_bias += bias  # 여러 에이전트의 편향을 합산
	
	# 주변 에이전트 수로 평균화
	if nearby_agents.size() > 1:
		memory_bias /= (nearby_agents.size() - 1)  # 자신 제외
	
	# 성격, 기억, 목표를 모두 고려한 유틸리티 계산
	utilities[ActionType.WANDER] = utility_ai.calculate_wander_utility(hunger, energy, trust, personality, memory_bias, primary_goal)
	utilities[ActionType.SEEK_FOOD] = utility_ai.calculate_food_utility(hunger, energy, trust, personality, memory_bias, primary_goal)
	utilities[ActionType.REST] = utility_ai.calculate_rest_utility(hunger, energy, trust, personality, memory_bias, primary_goal)
	utilities[ActionType.TRADE] = utility_ai.calculate_trade_utility(hunger, energy, trust, personality, memory_bias, primary_goal)
	utilities[ActionType.FLEE] = utility_ai.calculate_flee_utility(hunger, energy, trust, personality, memory_bias, primary_goal)
	
	return utilities

func setup_action():
	match current_action:
		ActionType.WANDER:
			set_random_target()
		ActionType.SEEK_FOOD:
			find_nearest_food()
		ActionType.REST:
			target_position = global_position
		ActionType.TRADE:
			find_trade_partner()
		ActionType.FLEE:
			flee_from_danger()

func execute_action(delta):
	state_timer += delta
	update_state_icon()
	
	match current_action:
		ActionType.SEEK_FOOD:
			if target_resource and is_instance_valid(target_resource):
				if global_position.distance_to(target_resource.global_position) < 20:
					consume_resource()
		ActionType.TRADE:
			if target_agent and is_instance_valid(target_agent):
				if global_position.distance_to(target_agent.global_position) < 30:
					attempt_trade()
		ActionType.REST:
			if state_timer > 3.0:
				set_random_target()

func update_state_icon():
	var state_icon = get_node_or_null("StateIcon")
	if state_icon:
		state_icon.text = get_state_emoji()
	
	# 체력바도 업데이트
	update_health_bar()

func consume_resource():
	if target_resource and is_instance_valid(target_resource):
		hunger = max(0, hunger - 40)  # 자원 섭취 시 더 많이 회복 (30→40)
		energy = min(100, energy + 15)  # 에너지 회복량 증가 (10→15)
		
		# 섭취 애니메이션 효과
		play_consume_animation()
		add_action_indicator("🍽️", Color.LIGHT_GREEN)
		
		# 이벤트 로그에 기록
		if game_manager and game_manager.event_logger:
			var resource_name = "알 수 없는 자원"
			if target_resource.resource_type:
				match target_resource.resource_type:
					"grain":
						resource_name = "곡물"
					"meat":
						resource_name = "고기"
					"carrot":
						resource_name = "당근"
					"berry":
						resource_name = "베리"
			game_manager.event_logger.log_resource_consumption(tribe_name, resource_name)
		
		if game_manager:
			game_manager.remove_resource(target_resource)
		target_resource = null
		set_random_target()

func play_consume_animation():
	# 섭취 시 크기가 잠깐 커졌다 작아지는 효과
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
	
	# 회복 이펙트 - 초록색 깜빡임
	var pixel_art = get_node_or_null("PixelArt")
	if pixel_art:
		tween.parallel().tween_property(pixel_art, "modulate", Color.GREEN, 0.1)
		tween.tween_property(pixel_art, "modulate", Color.WHITE, 0.3)

func find_nearest_food():
	if game_manager:
		target_resource = game_manager.get_nearest_resource(global_position)
		if target_resource:
			target_position = target_resource.global_position

func find_trade_partner():
	if game_manager:
		var nearby_agents = game_manager.get_agents_in_range(global_position, 100)
		if nearby_agents.size() > 1:
			for agent in nearby_agents:
				if agent != self and agent.trust > 40:
					target_agent = agent
					target_position = agent.global_position
					break

func flee_from_danger():
	if game_manager:
		var nearby_agents = game_manager.get_agents_in_range(global_position, 50)
		if nearby_agents.size() > 3:
			var flee_direction = Vector2.ZERO
			for agent in nearby_agents:
				if agent != self:
					flee_direction += (global_position - agent.global_position).normalized()
			flee_direction = flee_direction.normalized()
			target_position = global_position + flee_direction * 100


func attempt_trade():
	if target_agent and is_instance_valid(target_agent):
		var base_success = target_agent.trust > 30 and trust > 30
		var target_agent_id = target_agent.get_instance_id()
		
		# 기억 편향에 따른 거래 성공률 조정
		var memory_bias = get_memory_bias_towards(target_agent_id)
		var success_rate_modifier = memory_bias * 0.3  # -0.3 ~ +0.3
		
		# 성격에 따른 거래 성향
		var my_trade_willingness = (personality.sociability - personality.greed) / 100.0
		var generosity_factor = max(0.5, 1.0 + my_trade_willingness * 0.5)
		
		# 부족 시스템을 통한 협력 보너스
		var cooperation_result = null
		if game_manager and game_manager.tribe_system:
			cooperation_result = game_manager.tribe_system.handle_tribe_cooperation(self, target_agent)
		
		var final_success_rate = 0.6 + success_rate_modifier
		if cooperation_result:
			final_success_rate = max(final_success_rate, cooperation_result.success_rate)
		
		if (base_success or randf() < final_success_rate) and randf() < final_success_rate:
			# 성공적인 교역
			var hunger_relief = 5.0 * generosity_factor
			var trust_gain = 2.0
			
			if cooperation_result and cooperation_result.same_tribe:
				# 같은 부족끼리는 이미 TribeSystem에서 보너스 처리됨
				pass
			else:
				hunger -= hunger_relief
				target_agent.hunger -= hunger_relief
				trust += trust_gain
				target_agent.trust += trust_gain
			
			# 긍정적 기억 추가
			add_memory(MemoryType.TRADE_SUCCESS, target_agent_id, "성공적인 거래")
			if target_agent.has_method("add_memory"):
				target_agent.add_memory(MemoryType.COOPERATION, get_instance_id(), "도움을 받음")
			
			if game_manager:
				game_manager.record_trade()
			
			print("💰 ", tribe_name, " ↔ ", target_agent.tribe_name, " 거래 성공!")
			
			# 거래 성공 시각 효과
			add_action_indicator("💰", Color.GOLD)
			if target_agent.has_method("add_action_indicator"):
				target_agent.add_action_indicator("💰", Color.GOLD)
			
			# 이벤트 로그에 기록
			if game_manager and game_manager.event_logger:
				game_manager.event_logger.log_trade_success(tribe_name, target_agent.tribe_name)
		else:
			# 거래 실패
			trust -= 5
			target_agent.trust -= 5
			
			# 부정적 기억 추가
			add_memory(MemoryType.BETRAYAL, target_agent_id, "거래 거부당함")
			if target_agent.has_method("add_memory"):
				target_agent.add_memory(MemoryType.CONFLICT, get_instance_id(), "거래 시도 실패")
			
			print("💔 ", tribe_name, " ↔ ", target_agent.tribe_name, " 거래 실패!")
			
			# 거래 실패 시각 효과
			add_action_indicator("💔", Color.GRAY)
			if target_agent.has_method("add_action_indicator"):
				target_agent.add_action_indicator("💔", Color.GRAY)
			
			# 이벤트 로그에 기록
			if game_manager and game_manager.event_logger:
				game_manager.event_logger.log_trade_failure(tribe_name, target_agent.tribe_name)
			
		target_agent = null
		set_random_target()

func set_random_target():
	target_position = Vector2(
		randf_range(16, 200 * 32 - 16),  # 맵 너비 200으로 확대
		randf_range(16, 120 * 32 - 16)   # 맵 높이 120으로 확대
	)

func move_towards_target(delta):
	if global_position.distance_to(target_position) > 10:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
		
		# 이동 중 애니메이션 효과
		add_walking_animation(direction)
	else:
		velocity = Vector2.ZERO
		if current_action == ActionType.WANDER:
			set_random_target()

func add_walking_animation(direction: Vector2):
	# 걷는 동안 약간의 위아래 움직임 효과
	var pixel_container = get_node_or_null("PixelArt")
	if pixel_container:
		var walk_cycle = sin(game_time * 8.0) * 0.5
		pixel_container.position.y = walk_cycle
		
		# 이동 방향에 따른 반짝임 효과
		if randf() < 0.1:  # 10% 확률로 반짝임
			add_movement_sparkle(direction)

func add_movement_sparkle(direction: Vector2):
	# 이동 중 작은 먼지 효과
	var dust = Label.new()
	dust.text = "·"
	dust.position = Vector2(
		randf_range(-8, 8) - direction.x * 10,
		randf_range(-8, 8) - direction.y * 10
	)
	dust.add_theme_font_size_override("font_size", 4)
	dust.modulate = Color(0.6, 0.5, 0.4, 0.7)
	add_child(dust)
	
	# 먼지가 사라지는 애니메이션
	var tween = create_tween()
	tween.parallel().tween_property(dust, "modulate:a", 0.0, 0.8)
	tween.parallel().tween_property(dust, "position", dust.position + Vector2(0, -5), 0.8)
	tween.tween_callback(dust.queue_free)

func add_action_indicator(action_name: String, color: Color):
	# 행동 시 시각적 피드백
	var indicator = Label.new()
	indicator.text = action_name
	indicator.position = Vector2(-10, -20)
	indicator.add_theme_font_size_override("font_size", 8)
	indicator.add_theme_color_override("font_color", color)
	indicator.modulate = Color(1, 1, 1, 0.9)
	add_child(indicator)
	
	# 위로 떠오르며 사라지는 효과
	var tween = create_tween()
	tween.parallel().tween_property(indicator, "position", Vector2(-10, -35), 1.5)
	tween.parallel().tween_property(indicator, "modulate:a", 0.0, 1.5)
	tween.tween_callback(indicator.queue_free)

func add_health_warning_effect():
	# 체력이 낮을 때 경고 효과
	if health < 30:
		var warning = Label.new()
		warning.text = "⚠️"
		warning.position = Vector2(-5, -25)
		warning.add_theme_font_size_override("font_size", 10)
		warning.modulate = Color.RED
		add_child(warning)
		
		# 깜빡이는 효과
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(warning, "modulate:a", 0.3, 0.5)
		tween.tween_property(warning, "modulate:a", 1.0, 0.5)
		
		# 3초 후 제거
		get_tree().create_timer(3.0).timeout.connect(func(): 
			if is_instance_valid(warning):
				warning.queue_free()
		)

func practice_profession():
	# 전문 분야 연습으로 실력 향상
	if randf() < 0.3:  # 30% 확률로 연습
		specialization_level += learning_speed * 0.5
		
		# 게임매니저에 기술 학습 알림
		if game_manager and game_manager.knowledge_system:
			var tech_type = get_tech_type_from_profession()
			if tech_type >= 0:
				game_manager.knowledge_system.learn_skill(get_instance_id(), tech_type, learning_speed * 0.5)

func share_knowledge_with_nearby():
	# 근처 에이전트와 지식 공유
	if randf() < teaching_skill * 0.1 and game_manager:  # 가르치는 능력에 따라
		var nearby_agents = game_manager.get_agents_in_range(global_position, 50)
		
		for other_agent in nearby_agents:
			if other_agent != self and is_instance_valid(other_agent):
				if randf() < 0.1:  # 10% 확률로 지식 전수
					if game_manager.knowledge_system:
						var tech_type = get_tech_type_from_profession()
						if tech_type >= 0:
							game_manager.knowledge_system.share_knowledge(
								get_instance_id(), 
								other_agent.get_instance_id(), 
								tech_type
							)

func get_tech_type_from_profession() -> int:
	# 직업에 따른 기술 타입 반환
	match profession:
		"농부":
			return 0  # FARMING
		"사냥꾼":
			return 1  # HUNTING
		"장인":
			return 2  # CRAFTING
		"의사":
			return 3  # MEDICINE
		"건축가":
			return 4  # CONSTRUCTION
		"상인":
			return 6  # TRADE
		"교사":
			return 5  # SOCIAL
		"전사":
			return 7  # WARFARE
		_:
			return -1

func innovate():
	# 혁신 시도
	if randf() < innovation_chance:
		specialization_level += 10  # 혁신 성공 시 대폭 향상
		print("💡 ", tribe_name, " (", profession, ")이 혁신을 이뤘습니다!")
		
		# 혁신 효과 시각화
		add_action_indicator("💡", Color.GOLD)
