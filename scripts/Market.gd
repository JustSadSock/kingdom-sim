extends Resource
class_name Market

var settlement_id: int = -1
var stock := {
    "food": 100.0,
    "wood": 50.0,
    "grain": 0.0,
    "meat": 0.0,
}
var prices := {
    "food": 1.0,
    "wood": 0.7,
    "grain": 1.0,
    "meat": 1.5,
}
var daily_demand := {}
var daily_supply := {}

func register_buy_request(good: String, amount: float) -> void:
    daily_demand[good] = daily_demand.get(good, 0.0) + amount

func register_sell_request(good: String, amount: float) -> void:
    daily_supply[good] = daily_supply.get(good, 0.0) + amount

func resolve_trades() -> void:
    for good in prices.keys():
        var demand := daily_demand.get(good, 0.0)
        var supply := daily_supply.get(good, 0.0)
        var trade_amount := min(demand, supply)
        stock[good] = stock.get(good, 0.0) + supply - demand
        stock[good] = max(stock[good], 0.0)
        var ratio := demand / max(supply, 0.01)
        var new_price := prices[good] * clamp(ratio, 0.5, 3.0)
        prices[good] = lerp(prices[good], new_price, 0.5)
    daily_demand.clear()
    daily_supply.clear()
