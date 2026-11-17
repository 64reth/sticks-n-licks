class_name StoryInventory
extends RefCounted
var item: String=""
func pickup(value: String) -> bool:
 if not item.is_empty() or value not in ["crate","stick"]:return false
 item=value
 return true
func remove(value: String) -> bool:
 if item!=value:return false
 item=""
 return true
