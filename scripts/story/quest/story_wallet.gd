class_name StoryWallet
extends RefCounted
var money: int=0
var rewards: Array[String]=[]
func grant(id: String, amount: int) -> bool:
 if rewards.has(id) or amount<0:return false
 rewards.append(id)
 money+=amount
 return true
