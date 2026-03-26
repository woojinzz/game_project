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
var decision_interval = 1.0

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

func setup(pos, manager):
	global_position = pos
	game_manager = manager
	var UtilityAI = load("res://scripts/UtilityAI.gd")
	utility_ai = UtilityAI.new()
	
	hunger = randf_range(30, 70)
	energy = randf_range(30, 70)
	trust = randf_range(30, 70)
	
	create_visual()
	setup_collision()

func create_visual():
	var sprite = ColorRect.new()
	sprite.size = Vector2(16, 16)
	sprite.position = Vector2(-8, -8)
	sprite.color = Color.BLUE
	add_child(sprite)

func setup_collision():
	var collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(16, 16)
	collision_shape.shape = shape
	add_child(collision_shape)

func _ready():
	set_random_target()

func _physics_process(delta):
	update_stats(delta)
	
	decision_timer += delta
	if decision_timer >= decision_interval:
		decision_timer = 0.0
		make_decision()
	
	execute_action(delta)
	move_towards_target(delta)

func update_stats(delta):
	hunger = min(100, hunger + delta * 5)
	energy = max(0, energy - delta * 2)
	
	if current_action == ActionType.REST:
		energy = min(100, energy + delta * 10)
	
	if hunger > 80:
		trust = max(0, trust - delta * 2)
	elif hunger < 20:
		trust = min(100, trust + delta * 1)

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
	
	utilities[ActionType.WANDER] = utility_ai.calculate_wander_utility(hunger, energy, trust)
	utilities[ActionType.SEEK_FOOD] = utility_ai.calculate_food_utility(hunger, energy, trust)
	utilities[ActionType.REST] = utility_ai.calculate_rest_utility(hunger, energy, trust)
	utilities[ActionType.TRADE] = utility_ai.calculate_trade_utility(hunger, energy, trust)
	utilities[ActionType.FLEE] = utility_ai.calculate_flee_utility(hunger, energy, trust)
	
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

func consume_resource():
	if target_resource and is_instance_valid(target_resource):
		hunger = max(0, hunger - 30)
		energy = min(100, energy + 10)
		trust = min(100, trust + 5)
		game_manager.remove_resource(target_resource)
		target_resource = null
		set_random_target()

func attempt_trade():
	if target_agent and is_instance_valid(target_agent):
		if target_agent.trust > 30 and trust > 30:
			hunger -= 5
			target_agent.hunger -= 5
			trust += 2
			target_agent.trust += 2
			if game_manager:
				game_manager.record_trade()
		else:
			trust -= 5
			target_agent.trust -= 5
		target_agent = null
		set_random_target()

func set_random_target():
	target_position = Vector2(
		randf_range(16, 50 * 32 - 16),
		randf_range(16, 30 * 32 - 16)
	)

func move_towards_target(delta):
	if global_position.distance_to(target_position) > 10:
		var direction = (target_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
	else:
		if current_action == ActionType.WANDER:
			set_random_target()
