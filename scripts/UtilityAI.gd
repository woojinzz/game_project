extends RefCounted

func calculate_wander_utility(hunger, energy, trust):
	var base_utility = 0.2
	var energy_factor = clamp(energy / 100.0, 0.0, 1.0)
	var hunger_factor = 1.0 - clamp(hunger / 100.0, 0.0, 1.0)
	
	return base_utility + (energy_factor * 0.3) + (hunger_factor * 0.2)

func calculate_food_utility(hunger, energy, trust):
	var hunger_urgency = clamp(hunger / 100.0, 0.0, 1.0)
	var energy_factor = clamp(energy / 100.0, 0.2, 1.0)
	
	if hunger > 70:
		hunger_urgency = pow(hunger_urgency, 2)
	
	return hunger_urgency * energy_factor * 0.9

func calculate_rest_utility(hunger, energy, trust):
	var energy_need = 1.0 - clamp(energy / 100.0, 0.0, 1.0)
	var hunger_penalty = clamp(hunger / 100.0, 0.0, 0.5)
	
	if energy < 30:
		energy_need = pow(energy_need, 0.5)
	
	return max(0, energy_need * 0.8 - hunger_penalty * 0.3)

func calculate_trade_utility(hunger, energy, trust):
	var trust_factor = clamp(trust / 100.0, 0.0, 1.0)
	var energy_factor = clamp(energy / 100.0, 0.3, 1.0)
	var hunger_moderate = 1.0 - abs(hunger - 50) / 50.0
	
	if trust < 20:
		return 0.0
	
	return trust_factor * energy_factor * hunger_moderate * 0.6

func calculate_flee_utility(hunger, energy, trust):
	var trust_fear = 1.0 - clamp(trust / 100.0, 0.0, 1.0)
	var energy_factor = clamp(energy / 100.0, 0.2, 1.0)
	var hunger_desperation = clamp(hunger / 100.0, 0.0, 1.0)
	
	if trust < 30 or hunger > 80:
		trust_fear += 0.3
	
	return clamp(trust_fear * energy_factor + hunger_desperation * 0.2, 0.0, 0.8)

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
