extends Resource
class_name Market

var settlement_id: int = -1
var stock: Dictionary = {
    "food": 100.0,
    "wood": 50.0,
    "grain": 0.0,
    "meat": 0.0,
}
var prices: Dictionary = {
    "food": 1.0,
    "wood": 0.7,
    "grain": 1.0,
    "meat": 1.5,
}
var daily_demand: Dictionary = {}
var daily_supply: Dictionary = {}

func register_buy_request(good: String, amount: float) -> void:
    daily_demand[good] = daily_demand.get(good, 0.0) + amount

func register_sell_request(good: String, amount: float) -> void:
    daily_supply[good] = daily_supply.get(good, 0.0) + amount

func resolve_trades() -> void:
    for good in prices.keys():
        var demand: float = daily_demand.get(good, 0.0)
        var supply: float = daily_supply.get(good, 0.0)
        var trade_amount: float = min(demand, supply)
        stock[good] = stock.get(good, 0.0) + supply - demand
        stock[good] = max(stock[good], 0.0)
        var ratio: float = demand / max(supply, 0.01)
        var new_price: float = prices[good] * clamp(ratio, 0.5, 3.0)
        prices[good] = lerp(prices[good], new_price, 0.5)
    daily_demand.clear()
    daily_supply.clear()
