class_name StoryWallet
extends RefCounted
var campaign: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/story/campaign_013.json"))
var money: int=0
func target() -> int:return int(campaign.rent_target)
func ready_to_pay() -> bool:return money>=target()
func reward_amount(id: String) -> int:
 if id=="crate_delivery":return int(campaign.delivery_reward)
 for encounter in campaign.encounters.values():
  if encounter.reward_id==id:return int(encounter.reward)
 return -1
func total_for(ids: Array, historical: Dictionary={}) -> int:
 var total:=0
 var seen: Array=[]
 for id in ids:
  if not id is String or seen.has(id) or reward_amount(id)<0:return -1
  seen.append(id)
  var amount=historical.get(id,reward_amount(id))
  if typeof(amount) not in [TYPE_INT,TYPE_FLOAT] or float(amount)!=floorf(float(amount)) or amount<0:return -1
  total+=int(amount)
 return total
var rewards: Array[String]=[]
var amounts: Dictionary={}
func grant(id: String, amount: int) -> bool:
 if rewards.has(id) or amount<0:return false
 rewards.append(id)
 amounts[id]=amount
 money+=amount
 return true
