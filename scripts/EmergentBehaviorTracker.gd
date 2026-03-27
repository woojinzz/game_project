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
	
	var behavior_data = {
		"agent_id": agent.get_instance_id(),
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
	var agent_id = agent.get_instance_id()
	
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
				update_agent_relationship(agent_id, nearby_agent.get_instance_id(), agent, nearby_agent)

func update_agent_relationship(agent_id, other_id, agent, other_agent):
	if not social_networks[agent_id].trust_relationships.has(other_id):
		social_networks[agent_id].trust_relationships[other_id] = agent.trust
		social_networks[agent_id].interaction_frequency[other_id] = 1
	else:
		# 상호작용 빈도 증가
		social_networks[agent_id].interaction_frequency[other_id] += 1
		
		# 신뢰도 관계 업데이트
		var current_trust = social_networks[agent_id].trust_relationships[other_id]
		var new_trust = (current_trust + agent.trust) / 2.0
		social_networks[agent_id].trust_relationships[other_id] = new_trust

func detect_emergent_patterns():
	detect_spontaneous_grouping()
	detect_resource_monopoly()
	detect_social_hierarchy()
	detect_cultural_transmission()
	detect_cooperation_cascade()
	detect_conflict_spiral()

func detect_spontaneous_grouping():
	if behavior_history.size() < 50:
		return
	
	var recent_positions = {}
	var group_threshold = 80.0  # 픽셀 거리
	var min_group_size = 3
	
	# 최근 위치들을 분석
	for i in range(max(0, behavior_history.size() - 50), behavior_history.size()):
		var data = behavior_history[i]
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
		if data.action == 1:  # SEEK_FOOD
			var agent_id = data.agent_id
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
		var network = social_networks[agent_id]
		var influence_score = 0.0
		
		# 연결 수와 신뢰도 기반 영향력 계산
		for other_id in network.trust_relationships:
			var trust = network.trust_relationships[other_id]
			var frequency = network.interaction_frequency[other_id]
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
		var action = data.action
		var agent_id = data.agent_id
		
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
		if data.action == 3:  # TRADE
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
		if data.action == 4:  # FLEE
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

func reset():
	behavior_history.clear()
	social_networks.clear()
	emergence_events.clear()
	
	for type in emergence_detection:
		emergence_detection[type] = false