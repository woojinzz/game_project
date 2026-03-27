extends Control
class_name EventBanner

@onready var event_label = $EventLabel
@onready var progress_bar = $ProgressBar
@onready var background = $Background

var is_showing = false
var current_event_info = {}

func _ready():
	setup_banner()
	visible = false

func setup_banner():
	# 화면 상단에 배치 (화면 크기에 반응)
	var viewport_size = get_viewport().size
	size = Vector2(min(400, viewport_size.x * 0.7), 60)
	position = Vector2((viewport_size.x - size.x) / 2, 10)  # 중앙 상단
	
	# 배경 설정
	var bg = ColorRect.new()
	bg.name = "Background"
	bg.color = Color(0.1, 0.1, 0.1, 0.9)
	bg.size = size
	add_child(bg)
	background = bg
	
	# 이벤트 라벨
	var label = Label.new()
	label.name = "EventLabel"
	label.text = ""
	label.position = Vector2(10, 5)
	label.size = Vector2(size.x - 20, 30)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", max(10, int(size.x / 30)))
	label.add_theme_color_override("font_color", Color.WHITE)
	add_child(label)
	event_label = label
	
	# 진행바
	var progress = ProgressBar.new()
	progress.name = "ProgressBar"
	progress.position = Vector2(10, 35)
	progress.size = Vector2(size.x - 20, 20)
	progress.min_value = 0
	progress.max_value = 100
	progress.value = 0
	progress.show_percentage = false
	add_child(progress)
	progress_bar = progress

func show_event(event_info: Dictionary):
	if not event_info.get("active", false):
		hide_banner()
		return
	
	current_event_info = event_info
	is_showing = true
	visible = true
	
	# 이벤트 텍스트 설정
	var event_name = event_info.get("name", "알 수 없는 이벤트")
	var description = event_info.get("description", "")
	event_label.text = event_name + " - " + description
	
	# 진행바 설정
	var progress = event_info.get("progress", 0.0) * 100
	progress_bar.value = progress
	
	# 이벤트 타입에 따른 색상 설정
	var event_type = event_info.get("type", 0)
	match event_type:
		0:  # ABUNDANT_HARVEST
			background.color = Color(0.1, 0.5, 0.1, 0.9)  # 초록
			progress_bar.modulate = Color.GREEN
		1:  # DROUGHT
			background.color = Color(0.5, 0.3, 0.1, 0.9)  # 갈색
			progress_bar.modulate = Color.ORANGE
		2:  # PLAGUE
			background.color = Color(0.5, 0.1, 0.1, 0.9)  # 빨간색
			progress_bar.modulate = Color.RED
		_:
			background.color = Color(0.1, 0.1, 0.1, 0.9)  # 기본

func hide_banner():
	is_showing = false
	visible = false
	current_event_info.clear()

func update_progress(event_info: Dictionary):
	if not is_showing or not event_info.get("active", false):
		hide_banner()
		return
	
	# 진행바 업데이트
	var progress = event_info.get("progress", 0.0) * 100
	progress_bar.value = progress
	
	# 남은 시간 표시
	var remaining_time = event_info.get("remaining_time", 0.0)
	var time_text = " (남은 시간: " + str(int(remaining_time)) + "초)"
	
	var event_name = event_info.get("name", "알 수 없는 이벤트")
	var description = event_info.get("description", "")
	event_label.text = event_name + " - " + description + time_text