extends Panel
class_name AgentDetailPanel

@onready var agent_id_label = $VBoxContainer/AgentHeader/AgentID
@onready var tribe_label = $VBoxContainer/AgentHeader/TribeLabel
@onready var age_label = $VBoxContainer/AgentHeader/AgeLabel

@onready var hunger_bar = $VBoxContainer/StatsSection/HungerBar
@onready var energy_bar = $VBoxContainer/StatsSection/EnergyBar  
@onready var trust_bar = $VBoxContainer/StatsSection/TrustBar

@onready var hunger_value = $VBoxContainer/StatsSection/HungerBar/HungerValue
@onready var energy_value = $VBoxContainer/StatsSection/EnergyBar/EnergyValue
@onready var trust_value = $VBoxContainer/StatsSection/TrustBar/TrustValue

@onready var current_action_label = $VBoxContainer/BehaviorSection/CurrentAction
@onready var relationships_list = $VBoxContainer/RelationshipSection/RelationshipsList

var selected_agent = null
var age_ticks = 0

func _ready():
	visible = false
	setup_korean_ui()
	create_ui_elements()

func setup_korean_ui():
	# 패널 스타일 설정
	modulate = Color(0.95, 0.95, 0.95, 0.95)
	
	# 기본 크기와 위치 (화면 크기에 반응)
	var viewport_size = get_viewport().size
	var scale = min(1.0, min(viewport_size.x / 1280.0, viewport_size.y / 720.0))
	size = Vector2(300 * scale, 400 * scale)
	position = Vector2(viewport_size.x - size.x - 20, 20)  # 오른쪽 상단

func create_ui_elements():
	# VBoxContainer 생성
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)
	
	# 헤더 섹션
	var header_section = VBoxContainer.new()
	header_section.name = "AgentHeader"
	vbox.add_child(header_section)
	
	var title_label = Label.new()
	title_label.text = "🔍 에이전트 상세 정보"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var scale = min(1.0, min(size.x / 300.0, size.y / 400.0))
	title_label.add_theme_font_size_override("font_size", max(10, int(16 * scale)))
	header_section.add_child(title_label)
	
	var id_label = Label.new()
	id_label.name = "AgentID"
	id_label.text = "ID: 선택되지 않음"
	header_section.add_child(id_label)
	agent_id_label = id_label
	
	var tribe_info = Label.new()
	tribe_info.name = "TribeLabel"
	tribe_info.text = "부족: 없음"
	header_section.add_child(tribe_info)
	tribe_label = tribe_info
	
	var age_info = Label.new()
	age_info.name = "AgeLabel" 
	age_info.text = "나이: 0 틱"
	header_section.add_child(age_info)
	age_label = age_info
	
	# 구분선
	var separator1 = HSeparator.new()
	vbox.add_child(separator1)
	
	# 스탯 섹션
	var stats_section = VBoxContainer.new()
	stats_section.name = "StatsSection"
	vbox.add_child(stats_section)
	
	var stats_title = Label.new()
	stats_title.text = "📊 현재 상태"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_section.add_child(stats_title)
	
	# 배고픔 바
	hunger_bar = create_stat_bar("🍽️ 배고픔", Color.ORANGE)
	stats_section.add_child(hunger_bar)
	hunger_value = hunger_bar.get_child(1)
	
	# 에너지 바
	energy_bar = create_stat_bar("⚡ 에너지", Color.YELLOW)
	stats_section.add_child(energy_bar)
	energy_value = energy_bar.get_child(1)
	
	# 신뢰도 바
	trust_bar = create_stat_bar("🤝 신뢰도", Color.GREEN)
	stats_section.add_child(trust_bar)
	trust_value = trust_bar.get_child(1)
	
	# 구분선
	var separator2 = HSeparator.new()
	vbox.add_child(separator2)
	
	# 행동 섹션
	var behavior_section = VBoxContainer.new()
	behavior_section.name = "BehaviorSection"
	vbox.add_child(behavior_section)
	
	var behavior_title = Label.new()
	behavior_title.text = "🎯 현재 행동"
	behavior_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	behavior_section.add_child(behavior_title)
	
	var action_label = Label.new()
	action_label.name = "CurrentAction"
	action_label.text = "행동: 선택된 에이전트 없음"
	behavior_section.add_child(action_label)
	current_action_label = action_label
	
	# 구분선
	var separator3 = HSeparator.new()
	vbox.add_child(separator3)
	
	# 성격 및 목표 섹션
	var personality_section = VBoxContainer.new()
	personality_section.name = "PersonalitySection"
	vbox.add_child(personality_section)
	
	var personality_title = Label.new()
	personality_title.text = "🧠 성격 & 목표"
	personality_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	personality_section.add_child(personality_title)
	
	var personality_info = Label.new()
	personality_info.name = "PersonalityInfo"
	personality_info.text = "선택된 에이전트 없음"
	personality_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	personality_info.custom_minimum_size = Vector2(size.x - 20, 150)
	personality_section.add_child(personality_info)
	
	# 구분선
	var separator4 = HSeparator.new()
	vbox.add_child(separator4)
	
	# 관계 섹션
	var relationship_section = VBoxContainer.new()
	relationship_section.name = "RelationshipSection"
	vbox.add_child(relationship_section)
	
	var relationship_title = Label.new()
	relationship_title.text = "👥 주요 관계"
	relationship_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	relationship_section.add_child(relationship_title)
	
	var relationships_container = VBoxContainer.new()
	relationships_container.name = "RelationshipsList"
	relationship_section.add_child(relationships_container)
	relationships_list = relationships_container

func create_stat_bar(label_text: String, color: Color) -> VBoxContainer:
	var container = VBoxContainer.new()
	container.name = label_text.replace(" ", "").replace("🍽️", "Hunger").replace("⚡", "Energy").replace("🤝", "Trust") + "Bar"
	
	var label = Label.new()
	label.text = label_text
	var scale = min(1.0, min(size.x / 300.0, size.y / 400.0))
	label.add_theme_font_size_override("font_size", max(8, int(12 * scale)))
	container.add_child(label)
	
	var progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 50
	progress_bar.show_percentage = false
	progress_bar.size = Vector2(size.x - 40, 20 * scale)
	
	# ProgressBar 스타일 설정
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = color
	style_box.corner_radius_top_left = 5
	style_box.corner_radius_top_right = 5
	style_box.corner_radius_bottom_left = 5
	style_box.corner_radius_bottom_right = 5
	progress_bar.add_theme_stylebox_override("fill", style_box)
	
	container.add_child(progress_bar)
	
	return container

func select_agent(agent):
	selected_agent = agent
	visible = true
	age_ticks = 0
	update_agent_info()

func get_personality_info() -> String:
	if not selected_agent:
		return "선택된 에이전트 없음"
	
	var personality = selected_agent.personality
	var info = "성격 분석:\n"
	info += "• 탐욕: " + str(int(personality.greed)) + "/100\n"
	info += "• 친화력: " + str(int(personality.sociability)) + "/100\n"
	info += "• 겁쟁이: " + str(int(personality.cowardice)) + "/100\n"
	info += "• 호기심: " + str(int(personality.curiosity)) + "/100\n"
	info += "• 복수심: " + str(int(personality.vengefulness)) + "/100\n"
	info += "\n성격 특성: " + selected_agent.get_personality_description()
	
	# 현재 목표 정보
	var primary_goal = selected_agent.get_current_primary_goal()
	if primary_goal.size() > 0:
		info += "\n\n현재 목표: " + selected_agent.get_goal_description(primary_goal)
	else:
		info += "\n\n현재 목표: 없음"
	
	# 최근 기억 정보
	if selected_agent.short_term_memory.size() > 0:
		info += "\n\n최근 기억 (" + str(selected_agent.short_term_memory.size()) + "/10):"
		for i in range(min(3, selected_agent.short_term_memory.size())):
			var memory = selected_agent.short_term_memory[-(i+1)]  # 최신부터
			info += "\n• " + selected_agent.get_memory_description(memory.type)
	
	return info

func deselect_agent():
	selected_agent = null
	visible = false

func _process(delta):
	if selected_agent and is_instance_valid(selected_agent):
		age_ticks += 1
		update_agent_info()
	elif selected_agent:
		# 에이전트가 삭제됨
		deselect_agent()

func update_agent_info():
	if not selected_agent or not is_instance_valid(selected_agent):
		return
	
	# 기본 정보 업데이트
	if agent_id_label:
		agent_id_label.text = "ID: " + str(selected_agent.get_instance_id())
	
	if tribe_label:
		tribe_label.text = "부족: " + selected_agent.tribe_name
		tribe_label.modulate = selected_agent.tribe_color
	
	if age_label:
		age_label.text = "나이: " + str(age_ticks) + " 틱"
	
	# 스탯 바 업데이트
	update_stat_bars()
	
	# 현재 행동 업데이트
	update_current_action()
	
	# 성격 및 목표 정보 업데이트
	update_personality_info()
	
	# 관계 정보 업데이트
	update_relationships()

func update_personality_info():
	var personality_info_label = get_node_or_null("VBoxContainer/PersonalitySection/PersonalityInfo")
	if personality_info_label:
		personality_info_label.text = get_personality_info()

func update_stat_bars():
	if hunger_bar and hunger_bar.get_child_count() > 1:
		var progress = hunger_bar.get_child(1) as ProgressBar
		if progress:
			progress.value = selected_agent.hunger
			var label = hunger_bar.get_child(0) as Label
			if label:
				label.text = "🍽️ 배고픔: " + str(int(selected_agent.hunger))
	
	if energy_bar and energy_bar.get_child_count() > 1:
		var progress = energy_bar.get_child(1) as ProgressBar
		if progress:
			progress.value = selected_agent.energy
			var label = energy_bar.get_child(0) as Label
			if label:
				label.text = "⚡ 에너지: " + str(int(selected_agent.energy))
	
	if trust_bar and trust_bar.get_child_count() > 1:
		var progress = trust_bar.get_child(1) as ProgressBar
		if progress:
			progress.value = selected_agent.trust
			var label = trust_bar.get_child(0) as Label
			if label:
				label.text = "🤝 신뢰도: " + str(int(selected_agent.trust))

func update_current_action():
	if not current_action_label:
		return
	
	var action_text = "행동: "
	match selected_agent.current_action:
		selected_agent.ActionType.WANDER:
			action_text += "🚶 배회 중"
		selected_agent.ActionType.SEEK_FOOD:
			action_text += "🍖 먹이찾기 중"
		selected_agent.ActionType.REST:
			action_text += "😴 휴식 중"
		selected_agent.ActionType.TRADE:
			action_text += "💼 교역 중"
		selected_agent.ActionType.FLEE:
			action_text += "💨 도망 중"
		_:
			action_text += "❓ 알 수 없음"
	
	current_action_label.text = action_text

func update_relationships():
	if not relationships_list:
		return
	
	# 기존 관계 라벨들 제거
	for child in relationships_list.get_children():
		child.queue_free()
	
	# 게임 매니저에서 다른 에이전트들과의 관계 가져오기
	if not selected_agent.game_manager:
		var no_data = Label.new()
		no_data.text = "관계 데이터 없음"
		relationships_list.add_child(no_data)
		return
	
	var relationships = get_top_relationships()
	
	if relationships.size() == 0:
		var no_relationships = Label.new()
		no_relationships.text = "아직 관계가 없습니다"
		relationships_list.add_child(no_relationships)
		return
	
	for i in range(min(3, relationships.size())):
		var rel = relationships[i]
		var rel_label = Label.new()
		var trust_level = ""
		
		if rel.trust > 70:
			trust_level = "💚 친밀"
		elif rel.trust > 40:
			trust_level = "💛 보통"
		else:
			trust_level = "💔 불신"
		
		rel_label.text = trust_level + " " + rel.agent.tribe_name + " (" + str(int(rel.trust)) + ")"
		rel_label.modulate = rel.agent.tribe_color
		relationships_list.add_child(rel_label)

func get_top_relationships() -> Array:
	var relationships = []
	var agents = selected_agent.game_manager.agents
	
	for agent in agents:
		if agent != selected_agent and is_instance_valid(agent):
			# 거리 기반으로 상호작용 가능성 계산 (임시)
			var distance = selected_agent.global_position.distance_to(agent.global_position)
			var interaction_strength = max(0, 100 - distance) / 100.0 * selected_agent.trust
			
			relationships.append({
				"agent": agent,
				"trust": interaction_strength
			})
	
	# 신뢰도 순으로 정렬
	relationships.sort_custom(func(a, b): return a.trust > b.trust)
	
	return relationships

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# 패널 외부 클릭시 닫기
			if visible and not get_global_rect().has_point(event.global_position):
				deselect_agent()