extends RefCounted
class_name TribeSystem

enum TribeType {
	RED,      # 빨간 부족
	BLUE,     # 파란 부족  
	GREEN,    # 초록 부족
	YELLOW    # 노란 부족
}

var tribe_names = {
	TribeType.RED: "불꽃 부족",
	TribeType.BLUE: "물결 부족", 
	TribeType.GREEN: "숲속 부족",
	TribeType.YELLOW: "태양 부족"
}

var tribe_colors = {
	TribeType.RED: Color.RED,
	TribeType.BLUE: Color.BLUE,
	TribeType.GREEN: Color.GREEN, 
	TribeType.YELLOW: Color.YELLOW
}

var tribe_members = {
	TribeType.RED: [],
	TribeType.BLUE: [],
	TribeType.GREEN: [],
	TribeType.YELLOW: []
}

var tribe_cooperation_bonus = {
	TribeType.RED: 1.2,    # 20% 협력 보너스
	TribeType.BLUE: 1.2,
	TribeType.GREEN: 1.2,
	TribeType.YELLOW: 1.2
}

func assign_agent_to_tribe(agent, agent_index: int):
	var tribe_type = agent_index % 4 as TribeType
	assign_agent_to_specific_tribe(agent, tribe_type)

func assign_agent_to_specific_tribe(agent, tribe_type: TribeType):
	agent.tribe = tribe_type
	agent.tribe_name = tribe_names[tribe_type]
	agent.tribe_color = tribe_colors[tribe_type]
	
	tribe_members[tribe_type].append(agent)
	
	# 에이전트 색상 변경
	update_agent_visual(agent)
	
	print("🏘️ ", agent.get_instance_id(), "번 에이전트가 ", tribe_names[tribe_type], "에 배정됨")

func update_agent_visual(agent):
	if not agent or not is_instance_valid(agent):
		return
	
	# 에이전트의 시각적 표현을 부족 색상으로 변경
	var visual_node = agent.get_child(0)  # ColorRect
	if visual_node and visual_node is ColorRect:
		visual_node.color = agent.tribe_color

func is_same_tribe(agent1, agent2) -> bool:
	if not agent1 or not agent2:
		return false
	return agent1.tribe == agent2.tribe

func get_tribe_cooperation_bonus(agent1, agent2) -> float:
	if is_same_tribe(agent1, agent2):
		return tribe_cooperation_bonus.get(agent1.tribe, 1.0)
	return 1.0

func get_tribe_members(tribe_type: TribeType) -> Array:
	return tribe_members.get(tribe_type, [])

func get_all_tribe_members(agent) -> Array:
	if not agent:
		return []
	return get_tribe_members(agent.tribe)

func calculate_tribe_influence(agent) -> float:
	var tribe_mates = get_all_tribe_members(agent)
	var influence = 0.0
	
	for mate in tribe_mates:
		if mate != agent and is_instance_valid(mate):
			var distance = agent.global_position.distance_to(mate.global_position)
			if distance < 100:  # 영향 범위 내
				influence += (100 - distance) / 100.0
	
	return influence

func handle_tribe_cooperation(agent1, agent2) -> Dictionary:
	var cooperation_data = {
		"same_tribe": is_same_tribe(agent1, agent2),
		"bonus": get_tribe_cooperation_bonus(agent1, agent2),
		"success_rate": 0.5
	}
	
	if cooperation_data.same_tribe:
		cooperation_data.success_rate = 0.8  # 같은 부족끼리 80% 성공률
		
		# 같은 부족끼리 더 많은 혜택
		var extra_trust = 3.0
		var extra_hunger_relief = 8.0
		
		agent1.trust = min(100, agent1.trust + extra_trust)
		agent2.trust = min(100, agent2.trust + extra_trust)
		agent1.hunger = max(0, agent1.hunger - extra_hunger_relief)
		agent2.hunger = max(0, agent2.hunger - extra_hunger_relief)
		
		print("🤝 같은 부족 협력: ", agent1.tribe_name, " 부족원들이 협력했습니다")
	else:
		cooperation_data.success_rate = 0.3  # 다른 부족끼리 30% 성공률
		
		if randf() > cooperation_data.success_rate:
			# 협력 실패 시 신뢰도 하락
			agent1.trust = max(0, agent1.trust - 5)
			agent2.trust = max(0, agent2.trust - 5)
			cooperation_data.success_rate = 0.0
			print("❌ 부족간 협력 실패: ", agent1.tribe_name, " vs ", agent2.tribe_name)
	
	return cooperation_data

func get_tribe_statistics() -> Dictionary:
	var stats = {}
	
	for tribe_type in TribeType.values():
		var members = get_tribe_members(tribe_type)
		var valid_members = []
		
		for member in members:
			if is_instance_valid(member):
				valid_members.append(member)
		
		var avg_hunger = 0.0
		var avg_energy = 0.0
		var avg_trust = 0.0
		
		if valid_members.size() > 0:
			for member in valid_members:
				avg_hunger += member.hunger
				avg_energy += member.energy  
				avg_trust += member.trust
			
			avg_hunger /= valid_members.size()
			avg_energy /= valid_members.size()
			avg_trust /= valid_members.size()
		
		stats[tribe_type] = {
			"name": tribe_names[tribe_type],
			"color": tribe_colors[tribe_type],
			"member_count": valid_members.size(),
			"avg_hunger": avg_hunger,
			"avg_energy": avg_energy,
			"avg_trust": avg_trust
		}
	
	return stats

func cleanup_invalid_members():
	for tribe_type in tribe_members:
		var valid_members = []
		for member in tribe_members[tribe_type]:
			if is_instance_valid(member):
				valid_members.append(member)
		tribe_members[tribe_type] = valid_members

func reset():
	for tribe_type in tribe_members:
		tribe_members[tribe_type].clear()
	
	print("🏘️ 부족 시스템이 초기화되었습니다")