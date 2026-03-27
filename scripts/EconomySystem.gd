extends RefCounted
class_name EconomySystem

# 경제 시스템 - 자원의 가치와 교역
var resource_values = {
	"grain": 1.0,
	"meat": 1.5,
	"carrot": 1.2,
	"berry": 0.8
}

var resource_rarity = {
	"grain": 1.0,
	"meat": 2.0,  # 희귀함
	"carrot": 1.3,
	"berry": 0.7  # 흔함
}

var tribal_wealth = {}    # 부족별 부
var trade_routes = {}     # 교역로
var market_prices = {}    # 시장 가격
var price_history = []    # 가격 변동 기록

func _init():
	# 초기 시장 가격 설정
	for resource in resource_values:
		market_prices[resource] = resource_values[resource]
	
	# 부족별 초기 부 설정
	for tribe_id in range(4):
		tribal_wealth[tribe_id] = 0.0
	
	print("💰 경제 시스템 초기화됨")

func update_market_prices(resource_counts: Dictionary):
	# 공급과 수요에 따른 가격 변동
	for resource in resource_values:
		var current_count = resource_counts.get(resource, 0)
		var base_supply = 20  # 기준 공급량
		
		# 희귀도에 따른 기준 가격
		var base_price = resource_values[resource] * resource_rarity[resource]
		
		# 공급량에 따른 가격 조정
		var supply_factor = base_supply / max(1, current_count)
		supply_factor = clamp(supply_factor, 0.3, 3.0)
		
		# 새로운 가격 계산 (점진적 변화)
		var new_price = base_price * supply_factor
		market_prices[resource] = lerp(market_prices[resource], new_price, 0.1)
		
		# 가격 변동 기록
		record_price_history(resource, market_prices[resource])

func record_price_history(resource: String, price: float):
	var record = {
		"resource": resource,
		"price": price,
		"timestamp": Time.get_time_dict_from_system()
	}
	price_history.append(record)
	
	# 최근 100개 기록만 유지
	if price_history.size() > 100:
		price_history.pop_front()

func calculate_trade_value(resource_type: String, quantity: int = 1) -> float:
	return market_prices.get(resource_type, 1.0) * quantity

func execute_trade(seller_tribe: int, buyer_tribe: int, resource_type: String, quantity: int) -> bool:
	var trade_value = calculate_trade_value(resource_type, quantity)
	
	# 거래 수수료 (10%)
	var fee = trade_value * 0.1
	var final_value = trade_value - fee
	
	# 부족 부의 이동
	tribal_wealth[seller_tribe] += final_value
	tribal_wealth[buyer_tribe] = max(0, tribal_wealth[buyer_tribe] - trade_value)
	
	# 교역로 기록
	record_trade_route(seller_tribe, buyer_tribe, resource_type, trade_value)
	
	print("💱 교역 성사: 부족", seller_tribe, " → 부족", buyer_tribe, " (", resource_type, " x", quantity, ", 가치: ", int(trade_value), ")")
	return true

func record_trade_route(tribe1: int, tribe2: int, resource: String, value: float):
	var route_key = str(min(tribe1, tribe2)) + "_" + str(max(tribe1, tribe2))
	
	if not trade_routes.has(route_key):
		trade_routes[route_key] = {
			"tribes": [tribe1, tribe2],
			"total_value": 0.0,
			"trade_count": 0,
			"main_resources": {}
		}
	
	var route = trade_routes[route_key]
	route.total_value += value
	route.trade_count += 1
	route.main_resources[resource] = route.main_resources.get(resource, 0) + 1

func get_wealthiest_tribe() -> int:
	var max_wealth = -1.0
	var wealthiest_tribe = 0
	
	for tribe_id in tribal_wealth:
		if tribal_wealth[tribe_id] > max_wealth:
			max_wealth = tribal_wealth[tribe_id]
			wealthiest_tribe = tribe_id
	
	return wealthiest_tribe

func get_economic_summary() -> Dictionary:
	var most_valuable_resource = ""
	var highest_price = 0.0
	
	for resource in market_prices:
		if market_prices[resource] > highest_price:
			highest_price = market_prices[resource]
			most_valuable_resource = resource
	
	return {
		"market_prices": market_prices.duplicate(),
		"tribal_wealth": tribal_wealth.duplicate(),
		"most_valuable_resource": most_valuable_resource,
		"active_trade_routes": trade_routes.size(),
		"total_trade_volume": get_total_trade_volume()
	}

func get_total_trade_volume() -> float:
	var total = 0.0
	for route_key in trade_routes:
		total += trade_routes[route_key].total_value
	return total

func simulate_economic_events():
	# 경제적 이벤트 시뮬레이션 (계절 변화, 자원 발견 등)
	if randf() < 0.05:  # 5% 확률로 경제 이벤트
		var event_type = randi() % 3
		
		match event_type:
			0:  # 풍년 - 농산물 가격 하락
				if market_prices.has("grain"):
					market_prices["grain"] *= 0.8
					market_prices["carrot"] *= 0.8
				print("🌾 풍년! 농산물 가격이 하락했습니다")
			
			1:  # 가뭄 - 모든 식료품 가격 상승
				for resource in ["grain", "carrot", "berry"]:
					if market_prices.has(resource):
						market_prices[resource] *= 1.3
				print("☀️ 가뭄! 식료품 가격이 상승했습니다")
			
			2:  # 새로운 사냥터 발견 - 고기 가격 하락
				if market_prices.has("meat"):
					market_prices["meat"] *= 0.9
				print("🦌 새로운 사냥터 발견! 고기 가격이 하락했습니다")