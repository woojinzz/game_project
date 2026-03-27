extends RefCounted
class_name UtilityAI

func calculate_wander_utility(hunger, energy, trust, personality, memory_bias = 0.0, primary_goal = {}):
	var base_utility = 0.2
	var energy_factor = clamp(energy / 100.0, 0.0, 1.0)
	var hunger_factor = 1.0 - clamp(hunger / 100.0, 0.0, 1.0)
	
	# 호기심 성격 영향
	var curiosity_bonus = (personality.curiosity / 100.0) * 0.3
	
	# 탐험 목표가 있으면 더 높은 점수
	var goal_bonus = 0.0
	if primary_goal.has("type") and primary_goal.type == 4:  # EXPLORATION
		goal_bonus = 0.4
	
	return base_utility + (energy_factor * 0.3) + (hunger_factor * 0.2) + curiosity_bonus + goal_bonus

func calculate_food_utility(hunger, energy, trust, personality, memory_bias = 0.0, primary_goal = {}):
	var hunger_urgency = clamp(hunger / 100.0, 0.0, 1.0)
	var energy_factor = clamp(energy / 100.0, 0.2, 1.0)
	
	if hunger > 70:
		hunger_urgency = pow(hunger_urgency, 2)
	
	# 탐욕 성격 영향 - 탐욕스러운 에이전트는 더 빨리 음식을 찾음
	var greed_factor = 1.0 + (personality.greed / 200.0)
	
	# 자원 독점 목표가 있으면 더 높은 점수
	var goal_bonus = 0.0
	if primary_goal.has("type") and primary_goal.type == 1:  # RESOURCE_MONOPOLY
		goal_bonus = 0.3
	
	return (hunger_urgency * energy_factor * 0.9 * greed_factor) + goal_bonus

func calculate_rest_utility(hunger, energy, trust, personality, memory_bias = 0.0, primary_goal = {}):
	var energy_need = 1.0 - clamp(energy / 100.0, 0.0, 1.0)
	var hunger_penalty = clamp(hunger / 100.0, 0.0, 0.5)
	
	if energy < 30:
		energy_need = pow(energy_need, 0.5)
	
	# 겁쟁이 성격 영향 - 겁이 많으면 더 자주 휴식
	var cowardice_bonus = (personality.cowardice / 100.0) * 0.2
	
	return max(0, energy_need * 0.8 - hunger_penalty * 0.3 + cowardice_bonus)

func calculate_trade_utility(hunger, energy, trust, personality, memory_bias = 0.0, primary_goal = {}):
	var trust_factor = clamp(trust / 100.0, 0.0, 1.0)
	var energy_factor = clamp(energy / 100.0, 0.3, 1.0)
	var hunger_moderate = 1.0 - abs(hunger - 50) / 50.0
	
	if trust < 20:
		return 0.0
	
	# 친화력 성격 영향 - 사교적인 에이전트는 더 자주 거래
	var sociability_bonus = (personality.sociability / 100.0) * 0.4
	
	# 탐욕 성격 영향 - 탐욕스러운 에이전트는 거래를 덜 선호
	var greed_penalty = (personality.greed / 100.0) * 0.3
	
	# 기억 편향 영향 - 긍정적 기억이 있으면 거래 가능성 증가
	var memory_bonus = max(0, memory_bias * 0.2)
	
	# 동맹 구축 목표가 있으면 더 높은 점수
	var goal_bonus = 0.0
	if primary_goal.has("type") and primary_goal.type == 2:  # ALLIANCE_BUILDING
		goal_bonus = 0.3
	
	var base_score = trust_factor * energy_factor * hunger_moderate * 0.6
	return max(0, base_score + sociability_bonus - greed_penalty + memory_bonus + goal_bonus)

func calculate_flee_utility(hunger, energy, trust, personality, memory_bias = 0.0, primary_goal = {}):
	var trust_fear = 1.0 - clamp(trust / 100.0, 0.0, 1.0)
	var energy_factor = clamp(energy / 100.0, 0.2, 1.0)
	var hunger_desperation = clamp(hunger / 100.0, 0.0, 1.0)
	
	if trust < 30 or hunger > 80:
		trust_fear += 0.3
	
	# 겁쟁이 성격 영향 - 겁이 많으면 더 자주 도망
	var cowardice_bonus = (personality.cowardice / 100.0) * 0.4
	
	# 부정적 기억 영향 - 나쁜 기억이 있으면 도망 가능성 증가
	var memory_fear = max(0, -memory_bias * 0.3)
	
	# 복수 목표가 있으면 도망 점수 감소 (복수를 위해 맞서려 함)
	var revenge_penalty = 0.0
	if primary_goal.has("type") and primary_goal.type == 4:  # REVENGE
		revenge_penalty = 0.3
	
	var base_score = trust_fear * energy_factor + hunger_desperation * 0.2
	return clamp(base_score + cowardice_bonus + memory_fear - revenge_penalty, 0.0, 0.8)

func apply_curve(value, steepness = 2.0):
	return pow(clamp(value, 0.0, 1.0), steepness)

func normalize_utilities(utilities_dict):
	var total = 0.0
	for key in utilities_dict:
		total += utilities_dict[key]
	
	if total > 0:
		for key in utilities_dict:
			utilities_dict[key] /= total
	
	return utilities_dict
