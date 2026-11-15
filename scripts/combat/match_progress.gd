class_name MatchProgress
extends RefCounted
var best_of: int = 3
var round_number: int = 1
var round_wins: Array[int] = [0, 0]
var round_winner: int = -1
var winner: int = -1

func reset(value: int = 3) -> void:
 best_of = maxi(1, value)
 if best_of % 2 == 0:
  best_of += 1
 round_number = 1
 round_wins = [0, 0]
 round_winner = -1
 winner = -1

func wins_needed() -> int:
 return best_of / 2 + 1

func award_round(player: int) -> bool:
 if player not in [0, 1] or round_winner >= 0 or winner >= 0:
  return false
 round_winner = player
 round_wins[player] += 1
 if round_wins[player] >= wins_needed():
  winner = player
 return true

func next_round() -> bool:
 if round_winner < 0 or winner >= 0:
  return false
 round_number += 1
 round_winner = -1
 return true
