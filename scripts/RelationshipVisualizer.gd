extends Node2D
class_name RelationshipVisualizer

var game_manager = null
var show_relationships = false

# 관계선 표시 임계값
var positive_threshold = 70.0  # 신뢰도 70 이상 -> 초록 선
var negative_threshold = -30.0  # 신뢰도 -30 이하 -> 빨간 선

var relationship_lines = []
var relationship_cache = {}
var cache_update_timer = 0.0
var cache_update_interval = 1.0  # 1초마다 관계 캐시 업데이트

func _ready():
	print("👥 관계선 시각화 시스템 초기화됨 (F키로 토글)")

func set_game_manager(manager):
	game_manager = manager

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F:
			toggle_relationship_display()

func toggle_relationship_display():
	show_relationships = !show_relationships
	
	if show_relationships:
		print("👥 관계선 표시 활성화")
		update_relationships()
	else:
		print("👥 관계선 표시 비활성화")
		clear_relationship_lines()

func _process(delta):
	if show_relationships:
		cache_update_timer += delta
		if cache_update_timer >= cache_update_interval:
			cache_update_timer = 0.0
			update_relationships()

func update_relationships():
	if not game_manager:
		return
	
	clear_relationship_lines()
	calculate_relationship_cache()
	draw_relationship_lines()

func calculate_relationship_cache():
	relationship_cache.clear()
	
	if not game_manager or not game_manager.emergence_tracker:
		return
	
	var social_networks = game_manager.emergence_tracker.social_networks
	
	for agent_id in social_networks:
		if agent_id <= 0:
			continue
			
		var agent = find_agent_by_id(agent_id)
		if not agent or not is_instance_valid(agent):
			continue
		
		var network = social_networks[agent_id]
		if not network.has("trust_relationships") or not network.has("interaction_frequency"):
			continue
			
		var trust_relationships = network.get("trust_relationships", {})
		var interaction_frequency = network.get("interaction_frequency", {})
		
		for other_id in trust_relationships:
			if other_id <= 0:
				continue
				
			var other_agent = find_agent_by_id(other_id)
			if not other_agent or not is_instance_valid(other_agent):
				continue
			
			var trust_level = trust_relationships[other_id]
			var frequency = interaction_frequency.get(other_id, 1)
			
			# 상호작용 빈도를 고려한 실제 관계 강도 계산
			var relationship_strength = trust_level * log(frequency + 1)
			
			# 양방향 관계이므로 한 번만 저장
			var pair_key = get_relationship_key(agent_id, other_id)
			
			if not relationship_cache.has(pair_key):
				relationship_cache[pair_key] = {
					"agent1": agent,
					"agent2": other_agent,
					"strength": relationship_strength,
					"frequency": frequency
				}

func find_agent_by_id(agent_id: int):
	if not game_manager or agent_id <= 0:
		return null
	
	for agent in game_manager.agents:
		if is_instance_valid(agent):
			var current_id = agent.get_instance_id()
			if current_id > 0 and current_id == agent_id:
				return agent
	
	return null

func get_relationship_key(id1: int, id2: int) -> String:
	# 더 작은 ID가 먼저 오도록 정렬하여 중복 방지
	if id1 < id2:
		return str(id1) + "_" + str(id2)
	else:
		return str(id2) + "_" + str(id1)

func draw_relationship_lines():
	if not game_manager:
		return
	
	for relationship_key in relationship_cache:
		var rel_data = relationship_cache[relationship_key]
		var strength = rel_data.strength
		
		# 임계값 체크
		if strength >= positive_threshold:
			draw_relationship_line(rel_data.agent1, rel_data.agent2, Color.GREEN, strength, true)
		elif strength <= negative_threshold:
			draw_relationship_line(rel_data.agent1, rel_data.agent2, Color.RED, abs(strength), false)

func draw_relationship_line(agent1, agent2, color: Color, strength: float, is_positive: bool):
	if not agent1 or not agent2 or not is_instance_valid(agent1) or not is_instance_valid(agent2):
		return
	
	var line = Line2D.new()
	line.add_point(agent1.global_position)
	line.add_point(agent2.global_position)
	
	# 관계 강도에 따른 선 굵기 (1~5)
	var line_width = clamp(strength / 20.0, 1.0, 5.0)
	line.width = line_width
	
	# 색상 설정 (관계 강도에 따른 투명도)
	var alpha = clamp(strength / 100.0, 0.3, 0.8)
	line.default_color = Color(color.r, color.g, color.b, alpha)
	
	# 선 스타일 설정
	if is_positive:
		# 긍정적 관계: 실선
		line.texture_mode = Line2D.LINE_TEXTURE_NONE
	else:
		# 부정적 관계: 점선 효과
		line.texture_mode = Line2D.LINE_TEXTURE_TILE
	
	add_child(line)
	relationship_lines.append(line)
	
	# 관계 정보 텍스트 (옵션)
	if strength > 80:
		draw_relationship_label(agent1, agent2, strength, is_positive)

func draw_relationship_label(agent1, agent2, strength: float, is_positive: bool):
	var midpoint = (agent1.global_position + agent2.global_position) / 2
	
	var label = Label.new()
	if is_positive:
		if strength > 90:
			label.text = "💚"  # 매우 친밀
		else:
			label.text = "💙"  # 친밀
	else:
		if strength > 50:
			label.text = "💔"  # 매우 적대적
		else:
			label.text = "😠"  # 적대적
	
	label.position = midpoint - Vector2(10, 10)
	label.add_theme_font_size_override("font_size", 12)
	
	add_child(label)
	relationship_lines.append(label)

func clear_relationship_lines():
	for line in relationship_lines:
		if is_instance_valid(line):
			line.queue_free()
	
	relationship_lines.clear()

func get_relationship_statistics() -> Dictionary:
	var stats = {
		"total_relationships": relationship_cache.size(),
		"positive_relationships": 0,
		"negative_relationships": 0,
		"neutral_relationships": 0,
		"strongest_bond": 0.0,
		"strongest_conflict": 0.0
	}
	
	for rel_key in relationship_cache:
		var rel_data = relationship_cache[rel_key]
		var strength = rel_data.strength
		
		if strength >= positive_threshold:
			stats.positive_relationships += 1
			stats.strongest_bond = max(stats.strongest_bond, strength)
		elif strength <= negative_threshold:
			stats.negative_relationships += 1
			stats.strongest_conflict = max(stats.strongest_conflict, abs(strength))
		else:
			stats.neutral_relationships += 1
	
	return stats

func highlight_agent_relationships(target_agent):
	if not show_relationships or not target_agent:
		return
	
	clear_relationship_lines()
	
	# 선택된 에이전트와 관련된 관계만 표시
	var agent_id = target_agent.get_instance_id()
	if agent_id <= 0:
		return
	
	for rel_key in relationship_cache:
		var rel_data = relationship_cache[rel_key]
		
		# 안전한 에이전트 접근 확인
		if not rel_data.has("agent1") or not rel_data.has("agent2") or not rel_data.has("strength"):
			continue
			
		if not is_instance_valid(rel_data.agent1) or not is_instance_valid(rel_data.agent2):
			continue
		
		# 선택된 에이전트가 관련된 관계인지 확인
		var agent1_id = rel_data.agent1.get_instance_id()
		var agent2_id = rel_data.agent2.get_instance_id()
		
		if agent1_id <= 0 or agent2_id <= 0:
			continue
			
		if agent1_id == agent_id or agent2_id == agent_id:
			var strength = rel_data.strength
			
			if strength >= positive_threshold:
				draw_relationship_line(rel_data.agent1, rel_data.agent2, Color.GREEN, strength, true)
			elif strength <= negative_threshold:
				draw_relationship_line(rel_data.agent1, rel_data.agent2, Color.RED, abs(strength), false)

func reset():
	clear_relationship_lines()
	relationship_cache.clear()
	show_relationships = false
	cache_update_timer = 0.0
	
	print("👥 관계선 시각화 시스템이 초기화되었습니다")