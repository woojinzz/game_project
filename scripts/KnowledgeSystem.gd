extends RefCounted
class_name KnowledgeSystem

# 기술과 지식 시스템
enum TechType {
	FARMING,        # 농업
	HUNTING,        # 사냥
	CRAFTING,       # 제작
	MEDICINE,       # 의학
	CONSTRUCTION,   # 건설
	SOCIAL,         # 사회 기술
	TRADE,          # 상거래
	WARFARE         # 전쟁술
}

enum KnowledgeLevel {
	NONE = 0,
	BASIC = 1,
	INTERMEDIATE = 2,
	ADVANCED = 3,
	EXPERT = 4
}

var tribal_knowledge = {}  # 부족별 기술 수준
var individual_skills = {} # 개인별 기능
var knowledge_spread_rate = 0.1

func _init():
	# 초기 부족 기술 수준 설정
	for tribe_id in range(4):
		tribal_knowledge[tribe_id] = {}
		for tech in TechType.values():
			tribal_knowledge[tribe_id][tech] = KnowledgeLevel.NONE
	print("🧠 지식 시스템 초기화됨")

func learn_skill(agent_id: int, tech_type: TechType, experience_gain: float = 1.0):
	if not individual_skills.has(agent_id):
		individual_skills[agent_id] = {}
		for tech in TechType.values():
			individual_skills[agent_id][tech] = 0.0
	
	# 개인 기술 향상
	individual_skills[agent_id][tech_type] += experience_gain
	
	# 개인 기술이 일정 수준에 도달하면 부족 기술도 향상
	var personal_level = get_skill_level(individual_skills[agent_id][tech_type])
	var agent_tribe = get_agent_tribe(agent_id)
	
	if agent_tribe >= 0 and personal_level > tribal_knowledge[agent_tribe][tech_type]:
		tribal_knowledge[agent_tribe][tech_type] = personal_level
		print("🎓 부족 ", agent_tribe, "이 ", get_tech_name(tech_type), " 기술을 발전시켰습니다! (레벨 ", personal_level, ")")

func get_skill_level(experience: float) -> KnowledgeLevel:
	if experience >= 100:
		return KnowledgeLevel.EXPERT
	elif experience >= 50:
		return KnowledgeLevel.ADVANCED
	elif experience >= 20:
		return KnowledgeLevel.INTERMEDIATE
	elif experience >= 5:
		return KnowledgeLevel.BASIC
	else:
		return KnowledgeLevel.NONE

func get_agent_tribe(agent_id: int) -> int:
	# 에이전트 ID로부터 부족 추정 (임시)
	return agent_id % 4

func share_knowledge(teacher_id: int, student_id: int, tech_type: TechType):
	if not individual_skills.has(teacher_id) or not individual_skills.has(student_id):
		return
	
	var teacher_skill = individual_skills[teacher_id].get(tech_type, 0.0)
	var student_skill = individual_skills[student_id].get(tech_type, 0.0)
	
	# 선생의 기술이 학생보다 높을 때만 전수
	if teacher_skill > student_skill:
		var knowledge_transfer = min(teacher_skill * 0.1, teacher_skill - student_skill)
		individual_skills[student_id][tech_type] += knowledge_transfer
		print("📚 지식 전수: ", get_tech_name(tech_type), " (", int(knowledge_transfer), ")")

func get_tech_name(tech_type: TechType) -> String:
	match tech_type:
		TechType.FARMING:
			return "농업"
		TechType.HUNTING:
			return "사냥"
		TechType.CRAFTING:
			return "제작"
		TechType.MEDICINE:
			return "의학"
		TechType.CONSTRUCTION:
			return "건설"
		TechType.SOCIAL:
			return "사회"
		TechType.TRADE:
			return "상거래"
		TechType.WARFARE:
			return "전쟁술"
		_:
			return "알 수 없음"

func get_tribal_tech_summary(tribe_id: int) -> Dictionary:
	var summary = {
		"tribe": tribe_id,
		"technologies": {},
		"total_level": 0
	}
	
	if tribal_knowledge.has(tribe_id):
		for tech in TechType.values():
			var level = tribal_knowledge[tribe_id][tech]
			summary.technologies[get_tech_name(tech)] = level
			summary.total_level += level
	
	return summary

func apply_tech_bonus(agent_id: int, tech_type: TechType) -> float:
	# 기술 수준에 따른 보너스 계산
	var personal_skill = 0.0
	if individual_skills.has(agent_id) and individual_skills[agent_id].has(tech_type):
		personal_skill = individual_skills[agent_id][tech_type]
	
	var skill_level = get_skill_level(personal_skill)
	return 1.0 + (skill_level * 0.3)  # 각 레벨마다 30% 보너스

func cleanup_agent_data(agent_id: int):
	if individual_skills.has(agent_id):
		individual_skills.erase(agent_id)