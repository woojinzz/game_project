extends Control
class_name ObserverControls

signal simulation_speed_changed(speed)
signal time_scale_changed(scale)
signal focus_agent_requested(agent)
signal analysis_mode_changed(mode)

@onready var speed_slider = $VBoxContainer/SpeedControl/SpeedSlider
@onready var time_label = $VBoxContainer/TimeInfo/TimeLabel
@onready var focus_button = $VBoxContainer/ObserverTools/FocusButton
@onready var analysis_button = $VBoxContainer/ObserverTools/AnalysisButton
@onready var reset_button = $VBoxContainer/ObserverTools/ResetButton

var game_manager
var current_time = 0.0
var is_paused = false
var analysis_mode = false
var focused_agent = null

# 관찰자 시점 특화 기능
enum ObserverMode {
	FREE_ROAM,           # 자유 관찰
	AGENT_FOLLOW,        # 특정 에이전트 추적
	HOTSPOT_ANALYSIS,    # 활동 집중 지역 분석
	EMERGENCE_TRACKING,  # 창발 현상 추적
	SOCIAL_NETWORK      # 사회적 관계 분석
}

var current_observer_mode = ObserverMode.FREE_ROAM

func _ready():
	setup_korean_observer_ui()
	connect_signals()

func setup_korean_observer_ui():
	if speed_slider:
		speed_slider.min_value = 0.1
		speed_slider.max_value = 3.0
		speed_slider.value = 1.0
		speed_slider.step = 0.1
	
	# 한국어 라벨 설정
	var speed_label = $VBoxContainer/SpeedControl/SpeedLabel
	if speed_label:
		speed_label.text = "⏱️ 시뮬레이션 속도"
	
	if time_label:
		time_label.text = "🕒 경과 시간: 0분 0초"
	
	if focus_button:
		focus_button.text = "🔍 에이전트 추적"
	
	if analysis_button:
		analysis_button.text = "📊 창발 분석"
	
	if reset_button:
		reset_button.text = "🔄 시뮬레이션 초기화"

func connect_signals():
	if speed_slider:
		speed_slider.value_changed.connect(_on_speed_changed)
	if focus_button:
		focus_button.pressed.connect(_on_focus_button_pressed)
	if analysis_button:
		analysis_button.pressed.connect(_on_analysis_button_pressed)
	if reset_button:
		reset_button.pressed.connect(_on_reset_button_pressed)

func _process(delta):
	if not is_paused:
		current_time += delta
		update_time_display()
	
	handle_observer_input()

func handle_observer_input():
	# 관찰자 시점 전용 키보드 입력
	if Input.is_action_just_pressed("ui_accept"):  # 스페이스바
		toggle_pause()
	
	if Input.is_action_just_pressed("ui_select"):  # 엔터
		cycle_observer_mode()
	
	# 숫자 키로 빠른 속도 조절
	if Input.is_key_pressed(KEY_1):
		set_simulation_speed(0.5)
	elif Input.is_key_pressed(KEY_2):
		set_simulation_speed(1.0)
	elif Input.is_key_pressed(KEY_3):
		set_simulation_speed(2.0)

func set_simulation_speed(speed: float):
	if speed_slider:
		speed_slider.value = speed
	simulation_speed_changed.emit(speed)

func toggle_pause():
	is_paused = !is_paused
	var pause_speed = 0.0 if is_paused else speed_slider.value
	simulation_speed_changed.emit(pause_speed)
	
	print("⏸️ 시뮬레이션 ", "일시정지" if is_paused else "재시작")

func cycle_observer_mode():
	match current_observer_mode:
		ObserverMode.FREE_ROAM:
			current_observer_mode = ObserverMode.AGENT_FOLLOW
			print("👁️ 관찰 모드: 에이전트 추적")
		ObserverMode.AGENT_FOLLOW:
			current_observer_mode = ObserverMode.HOTSPOT_ANALYSIS
			print("👁️ 관찰 모드: 활동 집중 지역 분석")
		ObserverMode.HOTSPOT_ANALYSIS:
			current_observer_mode = ObserverMode.EMERGENCE_TRACKING
			print("👁️ 관찰 모드: 창발 현상 추적")
		ObserverMode.EMERGENCE_TRACKING:
			current_observer_mode = ObserverMode.SOCIAL_NETWORK
			print("👁️ 관찰 모드: 사회적 관계 분석")
		ObserverMode.SOCIAL_NETWORK:
			current_observer_mode = ObserverMode.FREE_ROAM
			print("👁️ 관찰 모드: 자유 관찰")
	
	analysis_mode_changed.emit(current_observer_mode)

func update_time_display():
	if time_label:
		var minutes = int(current_time / 60)
		var seconds = int(current_time) % 60
		time_label.text = "🕒 경과 시간: " + str(minutes) + "분 " + str(seconds) + "초"

func set_game_manager(manager):
	game_manager = manager

func find_most_interesting_agent():
	if not game_manager or game_manager.agents.size() == 0:
		return null
	
	var most_interesting = null
	var max_interest_score = -1.0
	
	for agent in game_manager.agents:
		if not is_instance_valid(agent):
			continue
			
		var interest_score = calculate_agent_interest(agent)
		if interest_score > max_interest_score:
			max_interest_score = interest_score
			most_interesting = agent
	
	return most_interesting

func calculate_agent_interest(agent) -> float:
	var score = 0.0
	
	# 극한 상태일수록 흥미로움
	score += abs(agent.hunger - 50) / 50.0 * 2.0
	score += abs(agent.energy - 50) / 50.0 * 2.0
	score += abs(agent.trust - 50) / 50.0 * 2.0
	
	# 사회적 상호작용이 많을수록 흥미로움
	if agent.current_action == agent.ActionType.TRADE:
		score += 3.0
	elif agent.current_action == agent.ActionType.FLEE:
		score += 2.5
	
	# 근처 에이전트가 많을수록 흥미로움
	if game_manager:
		var nearby_count = game_manager.get_agents_in_range(agent.global_position, 100).size()
		score += nearby_count * 0.5
	
	return score

func _on_speed_changed(value: float):
	simulation_speed_changed.emit(value)

func _on_focus_button_pressed():
	var interesting_agent = find_most_interesting_agent()
	if interesting_agent:
		focused_agent = interesting_agent
		focus_agent_requested.emit(interesting_agent)
		print("🔍 흥미로운 에이전트 추적 시작")
	else:
		focused_agent = null
		print("🔍 추적할 에이전트를 찾을 수 없습니다")

func _on_analysis_button_pressed():
	analysis_mode = !analysis_mode
	
	if analysis_mode:
		analysis_button.text = "📊 분석 종료"
		print("📊 창발 현상 분석 모드 시작")
	else:
		analysis_button.text = "📊 창발 분석"
		print("📊 분석 모드 종료")
	
	analysis_mode_changed.emit(current_observer_mode if analysis_mode else ObserverMode.FREE_ROAM)

func _on_reset_button_pressed():
	print("🔄 시뮬레이션을 초기화합니다...")
	current_time = 0.0
	focused_agent = null
	analysis_mode = false
	
	if game_manager and game_manager.emergence_tracker:
		game_manager.emergence_tracker.reset()
	
	# 게임 매니저에게 리셋 요청
	if game_manager:
		game_manager.reset_simulation()

func get_observer_status() -> Dictionary:
	return {
		"mode": current_observer_mode,
		"time": current_time,
		"paused": is_paused,
		"focused_agent": focused_agent.get_instance_id() if focused_agent else null,
		"analysis_active": analysis_mode
	}

func display_emergence_notification(event: Dictionary):
	# 창발 현상 발생 시 시각적 알림
	var notification = event.description
	print("🌟 " + notification)
	
	# 추후 UI 패널에 알림 표시 기능 추가 가능