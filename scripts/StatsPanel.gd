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

func _ready():
	modulate = Color(0.1, 0.1, 0.1, 0.8)

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
		agent_count_label.text = "Agents: " + str(agents.size())
	
	if agents.size() > 0:
		var total_hunger = 0.0
		var total_energy = 0.0
		var total_trust = 0.0
		
		var seeking_food = 0
		var resting = 0
		var trading = 0
		var fleeing = 0
		
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
		
		var avg_hunger = total_hunger / agents.size()
		var avg_energy = total_energy / agents.size()
		var avg_trust = total_trust / agents.size()
		
		if avg_hunger_label:
			avg_hunger_label.text = "Avg Hunger: " + str(snapped(avg_hunger, 0.1))
		if avg_energy_label:
			avg_energy_label.text = "Avg Energy: " + str(snapped(avg_energy, 0.1))
		if avg_trust_label:
			avg_trust_label.text = "Avg Trust: " + str(snapped(avg_trust, 0.1))
		
		update_behavior_stats(seeking_food, resting, trading, fleeing)

func update_resource_stats(resources):
	if resource_count_label:
		resource_count_label.text = "Available Resources: " + str(resources.size())

func update_behavior_stats(seeking_food, resting, trading, fleeing):
	var conflict_threshold = 3
	var current_conflicts = fleeing
	
	if current_conflicts > conflict_count:
		conflict_count = current_conflicts
	
	if trading > trade_count:
		trade_count = trading
	
	if conflict_count_label:
		conflict_count_label.text = "Conflicts Detected: " + str(conflict_count)
	if trade_count_label:
		trade_count_label.text = "Trades Attempted: " + str(trade_count)

func reset_stats():
	conflict_count = 0
	trade_count = 0