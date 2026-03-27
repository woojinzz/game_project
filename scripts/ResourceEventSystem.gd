extends RefCounted
class_name ResourceEventSystem

enum EventType {
	NONE,
	ABUNDANT_HARVEST,  # 대풍년
	DROUGHT,          # 가뭄
	PLAGUE            # 전염병
}

var current_event = EventType.NONE
var event_timer = 0.0
var event_duration = 0.0
var event_interval = 1800.0  # 1800틱마다 이벤트 발생 (6배 더 드물게)
var tick_count = 0

var event_names = {
	EventType.ABUNDANT_HARVEST: "🌾 대풍년",
	EventType.DROUGHT: "🏜️ 가뭄",
	EventType.PLAGUE: "🦠 전염병"
}

var event_descriptions = {
	EventType.ABUNDANT_HARVEST: "자원이 풍부해졌습니다! (+200% 자원 생성)",
	EventType.DROUGHT: "가뭄이 발생했습니다. (자원 생성 중단)",
	EventType.PLAGUE: "전염병이 퍼지고 있습니다! (에이전트 에너지 감소)"
}

var game_manager = null
var original_resource_count = 30

func _init(manager):
	game_manager = manager
	if game_manager:
		original_resource_count = game_manager.resource_count

func update(delta):
	tick_count += 1
	
	if current_event != EventType.NONE:
		event_timer += delta
		if event_timer >= event_duration:
			end_current_event()
	else:
		# 새 이벤트 발생 체크
		if tick_count % int(event_interval) == 0:
			trigger_random_event()

func trigger_random_event():
	var event_types = [EventType.ABUNDANT_HARVEST, EventType.DROUGHT, EventType.PLAGUE]
	var selected_event = event_types[randi() % event_types.size()]
	
	start_event(selected_event)

func start_event(event_type: EventType):
	if current_event != EventType.NONE:
		end_current_event()
	
	current_event = event_type
	event_timer = 0.0
	
	match event_type:
		EventType.ABUNDANT_HARVEST:
			event_duration = 50.0  # 50틱 지속
			start_abundant_harvest()
		EventType.DROUGHT:
			event_duration = 100.0  # 100틱 지속
			start_drought()
		EventType.PLAGUE:
			event_duration = 80.0  # 80틱 지속
			start_plague()
	
	print("🎪 이벤트 시작: ", event_names[event_type])
	print("   ", event_descriptions[event_type])

func start_abundant_harvest():
	if not game_manager:
		return
	
	# 자원을 3배로 증가 (기존 + 추가 2배)
	var additional_resources = original_resource_count * 2
	
	for i in range(additional_resources):
		var resource_class = game_manager.GameResource
		var resource = resource_class.new()
		var pos = Vector2(
			randf_range(16, game_manager.map_width * 32 - 16),
			randf_range(16, game_manager.map_height * 32 - 16)
		)
		resource.setup(pos)
		game_manager.add_child(resource)
		game_manager.resources.append(resource)

func start_drought():
	if not game_manager:
		return
	
	# 기존 자원의 절반을 제거
	var resources_to_remove = []
	var remove_count = game_manager.resources.size() / 2
	
	for i in range(remove_count):
		if i < game_manager.resources.size():
			var resource = game_manager.resources[i]
			if is_instance_valid(resource):
				resources_to_remove.append(resource)
	
	for resource in resources_to_remove:
		game_manager.resources.erase(resource)
		resource.queue_free()

func start_plague():
	if not game_manager:
		return
	
	# 랜덤하게 5마리 선택해서 에너지 급감
	var agents = game_manager.agents.duplicate()
	agents.shuffle()
	
	var affected_count = min(5, agents.size())
	
	for i in range(affected_count):
		var agent = agents[i]
		if is_instance_valid(agent):
			agent.energy = max(10, agent.energy - 40)  # 에너지 40 감소, 최소 10
			print("🦠 ", agent.tribe_name, " 부족 에이전트가 전염병에 감염됨")

func end_current_event():
	if current_event == EventType.NONE:
		return
	
	print("🎪 이벤트 종료: ", event_names[current_event])
	
	match current_event:
		EventType.ABUNDANT_HARVEST:
			end_abundant_harvest()
		EventType.DROUGHT:
			end_drought()
		EventType.PLAGUE:
			end_plague()
	
	current_event = EventType.NONE
	event_timer = 0.0

func end_abundant_harvest():
	# 대풍년 종료 시 자원을 원래 수준으로 조정
	if not game_manager:
		return
	
	var excess_resources = game_manager.resources.size() - original_resource_count
	if excess_resources > 0:
		# 초과 자원 제거
		for i in range(excess_resources):
			if game_manager.resources.size() > original_resource_count:
				var resource = game_manager.resources[-1]
				game_manager.resources.pop_back()
				if is_instance_valid(resource):
					resource.queue_free()

func end_drought():
	# 가뭄 종료 시 자원을 원래 수준으로 복구
	if not game_manager:
		return
	
	var needed_resources = original_resource_count - game_manager.resources.size()
	
	for i in range(needed_resources):
		var resource_class = game_manager.GameResource
		var resource = resource_class.new()
		var pos = Vector2(
			randf_range(16, game_manager.map_width * 32 - 16),
			randf_range(16, game_manager.map_height * 32 - 16)
		)
		resource.setup(pos)
		game_manager.add_child(resource)
		game_manager.resources.append(resource)

func end_plague():
	# 전염병 종료 - 특별한 처리 없음 (자연 회복)
	print("🌿 전염병이 진정되었습니다")

func get_current_event_info() -> Dictionary:
	if current_event == EventType.NONE:
		return {"active": false}
	
	var remaining_time = max(0, event_duration - event_timer)
	
	return {
		"active": true,
		"type": current_event,
		"name": event_names[current_event],
		"description": event_descriptions[current_event],
		"remaining_time": remaining_time,
		"progress": event_timer / event_duration
	}

func force_event(event_type: EventType):
	# 테스트용 강제 이벤트 발생
	start_event(event_type)

func reset():
	end_current_event()
	tick_count = 0
	event_timer = 0.0
	print("🎪 이벤트 시스템이 초기화되었습니다")