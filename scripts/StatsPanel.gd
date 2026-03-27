extends Panel

@onready var agent_count_label = $VBoxContainer/AgentCount
@onready var avg_hunger_label = $VBoxContainer/AvgHunger
@onready var avg_energy_label = $VBoxContainer/AvgEnergy
@onready var avg_trust_label = $VBoxContainer/AvgTrust
@onready var resource_count_label = $VBoxContainer/ResourceCount
@onready var conflict_count_label = $VBoxContainer/ConflictCount
@onready var trade_count_label = $VBoxContainer/TradeCount

var conflict_count = 0
var trade_count = 0
var update_timer = 0.0
var update_interval = 0.5

# 부족 통계 라벨들
var tribe_stats_labels = {}

func _ready():
	modulate = Color(0.1, 0.1, 0.1, 0.8)
	setup_responsive_size()
	setup_korean_ui()

func setup_responsive_size():
	# 화면 크기에 반응하는 크기 조정
	var viewport_size = get_viewport().size
	var scale = min(1.0, min(viewport_size.x / 1280.0, viewport_size.y / 720.0))
	size = Vector2(250 * scale, viewport_size.y)
	
	# 폰트 크기 조정
	var font_scale = max(0.7, scale)
	for child in get_children():
		adjust_font_sizes_recursive(child, font_scale)

func adjust_font_sizes_recursive(node: Node, font_scale: float):
	if node is Label:
		var label = node as Label
		var base_font_size = 14
		if label.name == "Title":
			base_font_size = 16
		label.add_theme_font_size_override("font_size", max(8, int(base_font_size * font_scale)))
	
	for child in node.get_children():
		adjust_font_sizes_recursive(child, font_scale)

func setup_korean_ui():
	var title_label = $VBoxContainer/Title
	var agent_count_label = $VBoxContainer/AgentCount
	var avg_hunger_label = $VBoxContainer/AvgHunger
	var avg_energy_label = $VBoxContainer/AvgEnergy
	var avg_trust_label = $VBoxContainer/AvgTrust
	var resource_count_label = $VBoxContainer/ResourceCount
	var conflict_count_label = $VBoxContainer/ConflictCount
	var trade_count_label = $VBoxContainer/TradeCount
	
	if title_label:
		title_label.text = "🤖 AI 시뮬레이션 통계"
	if agent_count_label:
		agent_count_label.text = "🧬 에이전트: 0마리"
	if avg_hunger_label:
		avg_hunger_label.text = "🍽️ 평균 배고픔: 0.0"
	if avg_energy_label:
		avg_energy_label.text = "⚡ 평균 에너지: 0.0"
	if avg_trust_label:
		avg_trust_label.text = "🤝 평균 신뢰도: 0.0"
	if resource_count_label:
		resource_count_label.text = "🌾 사용가능 자원: 0개"
	if conflict_count_label:
		conflict_count_label.text = "⚔️ 감지된 충돌: 0회"
	if trade_count_label:
		trade_count_label.text = "💱 성공한 교역: 0회"
		
	# 부족 통계 라벨 생성 (동적으로 추가)
	create_tribe_stats_labels()

func update_stats(agents, resources):
	update_timer += get_process_delta_time()
	
	if update_timer >= update_interval:
		update_timer = 0.0
		
		var valid_agents = []
		for agent in agents:
			if is_instance_valid(agent):
				valid_agents.append(agent)
		
		var valid_resources = []
		for resource in resources:
			if is_instance_valid(resource) and resource.visible:
				valid_resources.append(resource)
		
		update_agent_stats(valid_agents)
		update_resource_stats(valid_resources)

func update_agent_stats(agents):
	if agent_count_label:
		agent_count_label.text = "🧬 에이전트: " + str(agents.size()) + "마리"
	
	if agents.size() > 0:
		var total_hunger = 0.0
		var total_energy = 0.0
		var total_trust = 0.0
		
		var seeking_food = 0
		var resting = 0
		var trading = 0
		var fleeing = 0
		var wandering = 0
		
		for agent in agents:
			total_hunger += agent.hunger
			total_energy += agent.energy
			total_trust += agent.trust
			
			match agent.current_action:
				agent.ActionType.SEEK_FOOD:
					seeking_food += 1
				agent.ActionType.REST:
					resting += 1
				agent.ActionType.TRADE:
					trading += 1
				agent.ActionType.FLEE:
					fleeing += 1
				agent.ActionType.WANDER:
					wandering += 1
		
		var avg_hunger = total_hunger / agents.size()
		var avg_energy = total_energy / agents.size()
		var avg_trust = total_trust / agents.size()
		
		if avg_hunger_label:
			avg_hunger_label.text = "🍽️ 평균 배고픔: " + str(snapped(avg_hunger, 0.1))
		if avg_energy_label:
			avg_energy_label.text = "⚡ 평균 에너지: " + str(snapped(avg_energy, 0.1))
		if avg_trust_label:
			avg_trust_label.text = "🤝 평균 신뢰도: " + str(snapped(avg_trust, 0.1))
		
		update_behavior_stats(seeking_food, resting, trading, fleeing, wandering)

func update_resource_stats(resources):
	if resource_count_label:
		resource_count_label.text = "🌾 사용가능 자원: " + str(resources.size()) + "개"

func update_behavior_stats(seeking_food, resting, trading, fleeing, wandering):
	var current_conflicts = fleeing
	
	if current_conflicts > conflict_count:
		conflict_count = current_conflicts
	
	if trading > trade_count:
		trade_count = trading
	
	if conflict_count_label:
		conflict_count_label.text = "⚔️ 감지된 충돌: " + str(conflict_count) + "회"
	if trade_count_label:
		trade_count_label.text = "💱 성공한 교역: " + str(trade_count) + "회"
		
	# 창발 현상 관찰을 위한 추가 정보
	update_emergent_behavior_info(seeking_food, resting, trading, fleeing, wandering)

func update_emergent_behavior_info(seeking_food, resting, trading, fleeing, wandering):
	# 행동 패턴 분석으로 창발 현상 탐지
	var total_agents = seeking_food + resting + trading + fleeing + wandering
	if total_agents == 0:
		return
	
	var behavior_diversity = calculate_behavior_diversity(seeking_food, resting, trading, fleeing, wandering)
	var social_cohesion = calculate_social_cohesion(trading, fleeing)
	
	# UI에 창발 현상 정보 표시 (추후 확장 가능)
	print("🔍 창발 현상 분석:")
	print("  - 행동 다양성: ", behavior_diversity)
	print("  - 사회적 결속력: ", social_cohesion)

func calculate_behavior_diversity(seeking_food, resting, trading, fleeing, wandering) -> float:
	var total = seeking_food + resting + trading + fleeing + wandering
	if total == 0:
		return 0.0
	
	var behaviors = [seeking_food, resting, trading, fleeing, wandering]
	var entropy = 0.0
	
	for behavior_count in behaviors:
		if behavior_count > 0:
			var probability = float(behavior_count) / total
			entropy -= probability * log(probability) / log(2.0)
	
	return entropy / log(5.0)  # 정규화 (5가지 행동)

func calculate_social_cohesion(trading, fleeing) -> float:
	var total_social_actions = trading + fleeing
	if total_social_actions == 0:
		return 0.5
	
	return float(trading) / total_social_actions

func create_tribe_stats_labels():
	# HSeparator 추가
	var tribe_separator = HSeparator.new()
	$VBoxContainer.add_child(tribe_separator)
	
	# 부족 제목
	var tribe_title = Label.new()
	tribe_title.text = "🏘️ 부족별 현황"
	tribe_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	$VBoxContainer.add_child(tribe_title)
	
	# 각 부족별 라벨 생성
	var tribe_names = ["🔴 불꽃 부족", "🔵 물결 부족", "🟢 숲속 부족", "🟡 태양 부족"]
	
	for i in range(4):
		var tribe_label = Label.new()
		tribe_label.text = tribe_names[i] + ": 0마리"
		$VBoxContainer.add_child(tribe_label)
		tribe_stats_labels[i] = tribe_label

func update_tribe_stats(game_manager):
	if not game_manager or not game_manager.tribe_system:
		return
	
	var tribe_stats = game_manager.tribe_system.get_tribe_statistics()
	var tribe_icons = ["🔴", "🔵", "🟢", "🟡"]
	
	for tribe_type in tribe_stats:
		var stats = tribe_stats[tribe_type]
		var label = tribe_stats_labels.get(tribe_type)
		
		if label:
			var icon = tribe_icons[tribe_type]
			var text = icon + " " + stats.name + ": " + str(stats.member_count) + "마리"
			if stats.member_count > 0:
				text += " (신뢰:" + str(int(stats.avg_trust)) + ")"
			label.text = text

func update_emergence_info(emergence_summary: Dictionary):
	# 창발 현상 정보 업데이트 (향후 UI 패널 확장 시 사용)
	var active_count = emergence_summary.get("active_phenomena", []).size()
	if active_count > 0:
		print("🌟 활성 창발 현상: ", active_count, "개")

func reset_stats():
	conflict_count = 0
	trade_count = 0