extends Node2D

@onready var tilemap = $TileMap
@onready var camera = $Camera2D
@onready var stats_panel = $UI/StatsPanel

var agents = []
var resources = []
var map_width = 50
var map_height = 30
var agent_count = 20
var resource_count = 30

var Agent = preload("res://scripts/Agent.gd")
var GameResource = preload("res://scripts/Resource.gd")

var simulation_speed = 1.0
var total_conflicts = 0
var total_trades = 0

func _ready():
	setup_tilemap()
	spawn_resources()
	spawn_agents()
	setup_camera()

func setup_tilemap():
	var tileset = TileSet.new()
	var texture = ImageTexture.new()
	var image = Image.create(32, 32, false, Image.FORMAT_RGB8)
	image.fill(Color.GREEN * 0.8)
	texture.set_image(image)
	
	var atlas_source = TileSetAtlasSource.new()
	atlas_source.texture = texture
	atlas_source.create_tile(Vector2i(0, 0))
	tileset.add_source(atlas_source, 0)
	
	tilemap.tile_set = tileset
	
	for x in range(map_width):
		for y in range(map_height):
			tilemap.set_cell(0, Vector2i(x, y), 0, Vector2i(0, 0))

func setup_camera():
	var center_x = map_width * 16
	var center_y = map_height * 16
	camera.global_position = Vector2(center_x, center_y)
	camera.zoom = Vector2(2, 2)

func spawn_resources():
	for i in range(resource_count):
		var resource = GameResource.new()
		var pos = Vector2(
			randf_range(0, map_width - 1) * 32 + 16,
			randf_range(0, map_height - 1) * 32 + 16
		)
		resource.setup(pos)
		add_child(resource)
		resources.append(resource)

func spawn_agents():
	for i in range(agent_count):
		var agent_scene = preload("res://scenes/Agent.tscn")
		var agent
		
		if agent_scene:
			agent = agent_scene.instantiate()
		else:
			agent = Agent.new()
		
		var pos = Vector2(
			randf_range(0, map_width - 1) * 32 + 16,
			randf_range(0, map_height - 1) * 32 + 16
		)
		agent.setup(pos, self)
		add_child(agent)
		agents.append(agent)

func get_nearest_resource(pos):
	var nearest = null
	var min_distance = INF
	
	for resource in resources:
		if not is_instance_valid(resource):
			continue
		var distance = pos.distance_to(resource.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest = resource
	
	return nearest

func get_agents_in_range(pos, range_distance):
	var nearby_agents = []
	for agent in agents:
		if not is_instance_valid(agent):
			continue
		if pos.distance_to(agent.global_position) <= range_distance:
			nearby_agents.append(agent)
	return nearby_agents

func remove_resource(resource):
	if resource in resources:
		resources.erase(resource)
	if is_instance_valid(resource):
		resource.queue_free()

func _process(delta):
	update_simulation(delta)
	update_stats()
	handle_conflicts()

func update_simulation(delta):
	Engine.time_scale = simulation_speed
	
	for i in range(agents.size() - 1, -1, -1):
		if not is_instance_valid(agents[i]):
			agents.remove(i)
	
	for i in range(resources.size() - 1, -1, -1):
		if not is_instance_valid(resources[i]):
			resources.remove(i)

func handle_conflicts():
	for i in range(agents.size()):
		var agent = agents[i]
		if not is_instance_valid(agent):
			continue
			
		var nearby_agents = get_agents_in_range(agent.global_position, 40)
		
		if nearby_agents.size() > 3:
			for nearby_agent in nearby_agents:
				if nearby_agent != agent and nearby_agent.hunger > 70:
					agent.trust = max(0, agent.trust - 1)
					nearby_agent.trust = max(0, nearby_agent.trust - 1)
					total_conflicts += 1

func record_trade():
	total_trades += 1

func update_stats():
	if stats_panel:
		stats_panel.update_stats(agents, resources)
