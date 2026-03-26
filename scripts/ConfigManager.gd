extends RefCounted
class_name ConfigManager

static var instance: ConfigManager
static var current_config: Dictionary = {}
static var current_environment: String = "development"

static func get_instance() -> ConfigManager:
	if not instance:
		instance = ConfigManager.new()
	return instance

static func load_environment(env_name: String = "development") -> bool:
	var config_path = "res://config/environments/" + env_name + ".json"
	
	if not FileAccess.file_exists(config_path):
		print("Config file not found: ", config_path)
		return false
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if not file:
		print("Failed to open config file: ", config_path)
		return false
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("Failed to parse JSON in: ", config_path)
		return false
	
	current_config = json.data
	current_environment = env_name
	
	print("Loaded environment config: ", env_name)
	return true

static func get_config(key_path: String, default_value = null):
	var keys = key_path.split(".")
	var current = current_config
	
	for key in keys:
		if current.has(key):
			current = current[key]
		else:
			return default_value
	
	return current

static func get_simulation_config() -> Dictionary:
	return get_config("simulation", {})

static func get_ai_settings() -> Dictionary:
	return get_config("ai_settings", {})

static func get_ui_settings() -> Dictionary:
	return get_config("ui", {})

static func is_debug_mode() -> bool:
	return get_config("debug_mode", false)

static func get_log_level() -> String:
	return get_config("logging.level", "INFO")

static func should_show_debug_info() -> bool:
	return get_config("ui.show_debug_info", false)

static func get_agent_count() -> int:
	return get_config("simulation.agent_count", 20)

static func get_resource_count() -> int:
	return get_config("simulation.resource_count", 30)

static func get_map_size() -> Vector2i:
	var size_config = get_config("simulation.map_size", {"width": 50, "height": 30})
	return Vector2i(size_config.get("width", 50), size_config.get("height", 30))

static func get_decision_interval() -> float:
	return get_config("ai_settings.decision_interval", 1.0)

static func get_stats_update_interval() -> float:
	return get_config("ui.stats_update_interval", 0.5)

static func enable_performance_monitoring() -> bool:
	return get_config("simulation.performance_monitoring", false)

static func enable_behavior_tracking() -> bool:
	return get_config("ai_settings.behavior_tracking", false)

static func apply_to_game_manager(game_manager):
	if not game_manager:
		return
	
	var sim_config = get_simulation_config()
	
	if sim_config.has("agent_count"):
		game_manager.agent_count = sim_config.agent_count
	if sim_config.has("resource_count"):
		game_manager.resource_count = sim_config.resource_count
	
	var map_size = get_map_size()
	game_manager.map_width = map_size.x
	game_manager.map_height = map_size.y
	
	print("Applied config to GameManager: ", current_environment)