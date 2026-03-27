extends RefCounted
class_name EmergentBehaviorTracker

var behavior_history: Array = []
var group_formations: Array = []
var social_networks: Dictionary = {}
var behavior_patterns: Dictionary = {}
var emergence_events: Array = []

# 창발 현상 유형
enum EmergenceType {
	SPONTANEOUS_GROUPING,     # 자발적 집단 형성
	COLLECTIVE_MIGRATION,     # 집단 이주
	RESOURCE_MONOPOLY,        # 자원 독점
	SOCIAL_HIERARCHY,         # 사회적 위계 형성
	CULTURAL_TRANSMISSION,    # 행동 전파
	TERRITORIAL_BEHAVIOR,     # 영역 행동
	COOPERATION_CASCADE,      # 협력 연쇄 반응
	CONFLICT_SPIRAL          # 갈등 악화 현상
}

var emergence_detection = {
	EmergenceType.SPONTANEOUS_GROUPING: false,
	EmergenceType.COLLECTIVE_MIGRATION: false,
	EmergenceType.RESOURCE_MONOPOLY: false,
	EmergenceType.SOCIAL_HIERARCHY: false,
	EmergenceType.CULTURAL_TRANSMISSION: false,
	EmergenceType.TERRITORIAL_BEHAVIOR: false,
	EmergenceType.COOPERATION_CASCADE: false,
	EmergenceType.CONFLICT_SPIRAL: false
}

func track_agent_behavior(agent, delta_time):
	if not agent or not is_instance_valid(agent):
		return
	
	var agent_id = agent.get_instance_id()
	# 유효하지 않은 ID 무시
	if agent_id <= 0:
		return
	
	# 에이전트 타입 확인 (우리가 만든 Agent 클래스인지)
	if not agent.has_method("get_instance_id"):
		return
	
	var behavior_data = {
		"agent_id": agent_id,
		"position": agent.global_position,
		"action": agent.current_action,
		"hunger": agent.hunger,
		"energy": agent.energy,
		"trust": agent.trust,
		"timestamp": Time.get_time_dict_from_system()
	}
	
	behavior_history.append(behavior_data)
	
	# 최근 1000개 기록만 유지 (메모리 관리)
	if behavior_history.size() > 1000:
		behavior_history.pop_front()
	
	update_social_network(agent)
	detect_emergent_patterns()

func update_social_network(agent):
	if not is_instance_valid(agent):
		return
	
	var agent_id = agent.get_instance_id()
	if agent_id <= 0:
		return
	
	if not social_networks.has(agent_id):
		social_networks[agent_id] = {
			"connections": [],
			"trust_relationships": {},
			"interaction_frequency": {}
		}
	
	# 근처 에이전트와의 관계 업데이트
	if agent.game_manager:
		var nearby_agents = agent.game_manager.get_agents_in_range(agent.global_position, 60)
		for nearby_agent in nearby_agents:
			if nearby_agent != agent and is_instance_valid(nearby_agent):
				var other_id = nearby_agent.get_instance_id()
				if other_id > 0:
					update_agent_relationship(agent_id, other_id, agent, nearby_agent)

func update_agent_relationship(agent_id, other_id, agent, other_agent):
	# 매우 안전한 딕셔너리 접근
	if not social_networks.has(agent_id):
		return
	
	var agent_network = social_networks.get(agent_id, {})
	if not agent_network.has("trust_relationships") or not agent_network.has("interaction_frequency"):
		return
	
	var trust_relationships = agent_network.get("trust_relationships", {})
	var interaction_frequency = agent_network.get("interaction_frequency", {})
	
	if not trust_relationships.has(other_id):
		trust_relationships[other_id] = agent.trust
		interaction_frequency[other_id] = 1
	else:
		# 상호작용 빈도 증가
		interaction_frequency[other_id] = interaction_frequency.get(other_id, 0) + 1
		
		# 신뢰도 관계 업데이트
		var current_trust = trust_relationships.get(other_id, 0.0)
		var new_trust = (current_trust + agent.trust) / 2.0
		trust_relationships[other_id] = new_trust

func detect_emergent_patterns():
	detect_spontaneous_grouping()
	detect_resource_monopoly()
	detect_social_hierarchy()
	detect_cultural_transmission()
	detect_cooperation_cascade()
	detect_conflict_spiral()

func detect_spontaneous_grouping():
	if behavior_history.size() < 30:  # 기준을 낮춰서 더 빨리 시작
		return
	
	var recent_positions = {}
	var group_threshold = 80.0  # 픽셀 거리
	var min_group_size = 3
	
	# 최근 위치들을 분석
	for i in range(max(0, behavior_history.size() - 50), behavior_history.size()):
		var data = behavior_history[i]
		# 안전한 딕셔너리 접근
		if data.has("agent_id") and data.has("position"):
			var agent_id = data.agent_id
			recent_positions[agent_id] = data.position
	
	var groups = find_spatial_clusters(recent_positions.values(), group_threshold)
	
	for group in groups:
		if group.size() >= min_group_size:
			if not emergence_detection[EmergenceType.SPONTANEOUS_GROUPING]:
				emergence_detection[EmergenceType.SPONTANEOUS_GROUPING] = true
				record_emergence_event(EmergenceType.SPONTANEOUS_GROUPING, 
					"🏘️ 자발적 집단 형성: " + str(group.size()) + "마리가 그룹을 형성했습니다")

func detect_resource_monopoly():
	if behavior_history.size() < 100:
		return
	
	var resource_access = {}
	var monopoly_threshold = 0.7  # 70% 이상 독점시
	
	for i in range(max(0, behavior_history.size() - 100), behavior_history.size()):
		var data = behavior_history[i]
		if data.has("action") and data.has("agent_id") and data.action == 1:  # SEEK_FOOD
			var agent_id = data.agent_id
			if agent_id > 0:
				resource_access[agent_id] = resource_access.get(agent_id, 0) + 1
	
	if resource_access.size() > 0:
		var total_access = 0
		var max_access = 0
		
		for agent_id in resource_access:
			var access_count = resource_access[agent_id]
			total_access += access_count
			if access_count > max_access:
				max_access = access_count
		
		var monopoly_ratio = float(max_access) / total_access
		
		if monopoly_ratio >= monopoly_threshold:
			if not emergence_detection[EmergenceType.RESOURCE_MONOPOLY]:
				emergence_detection[EmergenceType.RESOURCE_MONOPOLY] = true
				record_emergence_event(EmergenceType.RESOURCE_MONOPOLY,
					"🏛️ 자원 독점: 특정 에이전트가 자원의 " + str(int(monopoly_ratio * 100)) + "%를 독점했습니다")

func detect_social_hierarchy():
	var hierarchy_indicators = {}
	
	for agent_id in social_networks:
		if agent_id <= 0:
			continue
			
		var network = social_networks.get(agent_id, {})
		if not network.has("trust_relationships") or not network.has("interaction_frequency"):
			continue
			
		var trust_relationships = network.get("trust_relationships", {})
		var interaction_frequency = network.get("interaction_frequency", {})
		var influence_score = 0.0
		
		# 연결 수와 신뢰도 기반 영향력 계산
		for other_id in trust_relationships:
			if other_id <= 0:
				continue
			var trust = trust_relationships.get(other_id, 0.0)
			var frequency = interaction_frequency.get(other_id, 1)
			influence_score += trust * log(frequency + 1)
		
		hierarchy_indicators[agent_id] = influence_score
	
	if hierarchy_indicators.size() >= 3:
		var sorted_scores = hierarchy_indicators.values()
		sorted_scores.sort()
		
		var highest = sorted_scores[-1]
		var median = sorted_scores[sorted_scores.size() / 2]
		
		if highest > median * 2.0:  # 상위권이 중간값의 2배 이상
			if not emergence_detection[EmergenceType.SOCIAL_HIERARCHY]:
				emergence_detection[EmergenceType.SOCIAL_HIERARCHY] = true
				record_emergence_event(EmergenceType.SOCIAL_HIERARCHY,
					"👑 사회적 위계: 리더 에이전트가 등장했습니다")

func detect_cultural_transmission():
	var behavior_spreading = {}
	
	for i in range(max(0, behavior_history.size() - 200), behavior_history.size()):
		var data = behavior_history[i]
		if data.has("action") and data.has("agent_id"):
			var action = data.action
			var agent_id = data.agent_id
			
			if agent_id > 0:
				if not behavior_spreading.has(action):
					behavior_spreading[action] = {}
				
				behavior_spreading[action][agent_id] = true
	
	for action in behavior_spreading:
		var agent_count = behavior_spreading[action].size()
		if agent_count >= 15:  # 75% 이상이 같은 행동
			if not emergence_detection[EmergenceType.CULTURAL_TRANSMISSION]:
				emergence_detection[EmergenceType.CULTURAL_TRANSMISSION] = true
				record_emergence_event(EmergenceType.CULTURAL_TRANSMISSION,
					"🌊 행동 전파: " + get_action_name(action) + " 행동이 집단에 확산되었습니다")

func detect_cooperation_cascade():
	var recent_trades = 0
	var trade_threshold = 5
	
	for i in range(max(0, behavior_history.size() - 50), behavior_history.size()):
		var data = behavior_history[i]
		if data.has("action") and data.action == 3:  # TRADE
			recent_trades += 1
	
	if recent_trades >= trade_threshold:
		if not emergence_detection[EmergenceType.COOPERATION_CASCADE]:
			emergence_detection[EmergenceType.COOPERATION_CASCADE] = true
			record_emergence_event(EmergenceType.COOPERATION_CASCADE,
				"🤝 협력 연쇄: 에이전트들 사이에 협력의 연쇄반응이 시작되었습니다")

func detect_conflict_spiral():
	var recent_conflicts = 0
	var conflict_threshold = 8
	
	for i in range(max(0, behavior_history.size() - 50), behavior_history.size()):
		var data = behavior_history[i]
		if data.has("action") and data.action == 4:  # FLEE
			recent_conflicts += 1
	
	if recent_conflicts >= conflict_threshold:
		if not emergence_detection[EmergenceType.CONFLICT_SPIRAL]:
			emergence_detection[EmergenceType.CONFLICT_SPIRAL] = true
			record_emergence_event(EmergenceType.CONFLICT_SPIRAL,
				"⚔️ 갈등 악화: 에이전트들 사이에 광범위한 갈등이 확산되고 있습니다")

func find_spatial_clusters(positions: Array, threshold: float) -> Array:
	var clusters = []
	var visited = {}
	
	for i in range(positions.size()):
		if visited.has(i):
			continue
		
		var cluster = [i]
		visited[i] = true
		var queue = [i]
		
		while queue.size() > 0:
			var current_idx = queue.pop_front()
			var current_pos = positions[current_idx]
			
			for j in range(positions.size()):
				if visited.has(j):
					continue
				
				var distance = current_pos.distance_to(positions[j])
				if distance <= threshold:
					cluster.append(j)
					queue.append(j)
					visited[j] = true
		
		if cluster.size() >= 2:
			clusters.append(cluster)
	
	return clusters

func record_emergence_event(type: EmergenceType, description: String):
	var event = {
		"type": type,
		"description": description,
		"timestamp": Time.get_time_dict_from_system(),
		"agents_involved": behavior_history.size()
	}
	
	emergence_events.append(event)
	
	# 최근 50개 이벤트만 유지
	if emergence_events.size() > 50:
		emergence_events.pop_front()
	
	print("🔍 창발 현상 감지: ", description)

func get_action_name(action_type) -> String:
	match action_type:
		0: return "배회"
		1: return "먹이 찾기"
		2: return "휴식"
		3: return "교역"
		4: return "도망"
		_: return "알 수 없음"

func get_emergence_summary() -> Dictionary:
	var active_phenomena = []
	
	for type in emergence_detection:
		if emergence_detection[type]:
			active_phenomena.append(type)
	
	return {
		"active_phenomena": active_phenomena,
		"total_events": emergence_events.size(),
		"behavior_records": behavior_history.size(),
		"social_connections": social_networks.size()
	}

func cleanup_agent_data(agent_id: int):
	if agent_id <= 0:
		return
	
	# social_networks에서 해당 에이전트 데이터 완전 제거
	if social_networks.has(agent_id):
		social_networks.erase(agent_id)
		print("🧹 social_networks에서 에이전트 ", agent_id, " 제거")
	
	# 다른 에이전트들의 관계에서도 해당 에이전트 제거 (더 안전한 방식)
	var agent_ids_to_clean = social_networks.keys().duplicate()
	for other_agent_id in agent_ids_to_clean:
		if other_agent_id == agent_id:
			continue
			
		var network = social_networks.get(other_agent_id, {})
		
		# trust_relationships 정리
		if network.has("trust_relationships"):
			var trust_rels = network.get("trust_relationships", {})
			if trust_rels.has(agent_id):
				trust_rels.erase(agent_id)
		
		# interaction_frequency 정리
		if network.has("interaction_frequency"):
			var freq_data = network.get("interaction_frequency", {})
			if freq_data.has(agent_id):
				freq_data.erase(agent_id)
		
		# connections 정리
		if network.has("connections"):
			var connections = network.get("connections", [])
			for i in range(connections.size() - 1, -1, -1):
				if connections[i] == agent_id:
					connections.remove_at(i)
	
	# behavior_history에서 해당 에이전트 기록 제거 (더 안전한 방식)
	var history_size = behavior_history.size()
	for i in range(history_size - 1, -1, -1):
		if i < behavior_history.size():  # 인덱스 재검증
			var data = behavior_history[i]
			if data.has("agent_id") and data.agent_id == agent_id:
				behavior_history.remove_at(i)
	
	print("🧹 에이전트 ", agent_id, " 데이터 완전 정리 완료")

func cleanup_invalid_agent_references(game_manager):
	# 정기적으로 무효한 에이전트 참조 정리
	if not game_manager:
		return
		
	var valid_agent_ids = {}
	
	# GameManager에서 유효한 에이전트 ID들 수집
	for agent in game_manager.agents:
		if is_instance_valid(agent):
			var agent_id = agent.get_instance_id()
			if agent_id > 0:
				valid_agent_ids[agent_id] = true
	
	# social_networks에서 무효한 에이전트 제거
	var networks_to_remove = []
	for agent_id in social_networks:
		if not valid_agent_ids.has(agent_id):
			networks_to_remove.append(agent_id)
	
	for invalid_id in networks_to_remove:
		cleanup_agent_data(invalid_id)

func reset():
	behavior_history.clear()
	social_networks.clear()
	emergence_events.clear()
	
	for type in emergence_detection:
		emergence_detection[type] = false
