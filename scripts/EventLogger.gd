extends Control
class_name EventLogger

@onready var chat_scroll = $ChatScroll
@onready var chat_container = $ChatScroll/ChatContainer

var max_messages = 100
var message_count = 0

func _ready():
	setup_chat_window()

func setup_chat_window():
	var viewport_size = get_viewport().size
	var chat_width = min(400, viewport_size.x * 0.3)
	var chat_height = min(300, viewport_size.y * 0.4)
	
	size = Vector2(chat_width, chat_height)
	position = Vector2(viewport_size.x - chat_width - 20, viewport_size.y - chat_height - 20)
	
	var bg = ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.1, 0.9)
	bg.size = size
	add_child(bg)
	move_child(bg, 0)
	
	var title = Label.new()
	title.text = "실시간 이벤트 로그"
	title.position = Vector2(10, 5)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.add_theme_font_size_override("font_size", 12)
	add_child(title)
	
	var scroll = ScrollContainer.new()
	scroll.name = "ChatScroll"
	scroll.position = Vector2(5, 25)
	scroll.size = Vector2(size.x - 10, size.y - 30)
	scroll.follow_focus = true
	add_child(scroll)
	chat_scroll = scroll
	
	var container = VBoxContainer.new()
	container.name = "ChatContainer"
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(container)
	chat_container = container
	
	add_system_message("게임이 시작되었습니다!")

func add_message(message: String, color: Color = Color.WHITE, icon: String = ""):
	if not chat_container:
		return
	
	message_count += 1
	
	var msg_label = RichTextLabel.new()
	msg_label.fit_content = true
	msg_label.custom_minimum_size = Vector2(size.x - 30, 0)
	msg_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	msg_label.add_theme_color_override("default_color", color)
	msg_label.add_theme_font_size_override("normal_font_size", 10)
	
	var datetime_parts = Time.get_datetime_string_from_system().split(" ")
	var timestamp = "00:00"
	if datetime_parts.size() >= 2:
		timestamp = datetime_parts[1].substr(0, 5)
	var full_message = "[color=gray][" + timestamp + "][/color] " + icon + " " + message
	msg_label.text = full_message
	
	chat_container.add_child(msg_label)
	
	if message_count > max_messages:
		var oldest = chat_container.get_child(0)
		oldest.queue_free()
		message_count -= 1
	
	call_deferred("scroll_to_bottom")

func scroll_to_bottom():
	if chat_scroll:
		chat_scroll.scroll_vertical = chat_scroll.get_v_scroll_bar().max_value

func add_system_message(message: String):
	add_message(message, Color.LIGHT_BLUE, "🔧")

func log_agent_birth(agent_name: String, parent1: String, parent2: String):
	var message = agent_name + " 탄생! 부모: " + parent1 + " + " + parent2
	add_message(message, Color.GREEN, "👶")

func log_agent_death(agent_name: String, cause: String, age: int):
	var message = agent_name + " 사망 (" + cause + ", 나이: " + str(age) + ")"
	add_message(message, Color.RED, "💀")

func log_conflict(agent1: String, agent2: String, winner: String):
	var message = agent1 + " vs " + agent2 + " 충돌! 승자: " + winner
	add_message(message, Color.ORANGE, "⚔️")

func log_trade_success(agent1: String, agent2: String):
	var message = agent1 + " ↔ " + agent2 + " 거래 성공"
	add_message(message, Color.YELLOW, "💰")

func log_trade_failure(agent1: String, agent2: String):
	var message = agent1 + " ↔ " + agent2 + " 거래 실패"
	add_message(message, Color.GRAY, "💔")

func log_resource_consumption(agent_name: String, resource_type: String):
	var message = agent_name + "가 " + resource_type + " 자원을 소비"
	add_message(message, Color.LIGHT_GREEN, "🍽️")

func log_reproduction_attempt(agent1: String, agent2: String, success: bool):
	var message = ""
	var icon = ""
	var color = Color.WHITE
	
	if success:
		message = agent1 + " ♥ " + agent2 + " 번식 성공!"
		icon = "👶"
		color = Color.PINK
	else:
		message = agent1 + " ♥ " + agent2 + " 번식 실패"
		icon = "💔"
		color = Color.LIGHT_GRAY
	
	add_message(message, color, icon)
