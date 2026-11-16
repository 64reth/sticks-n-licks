class_name MenuTestInput
extends RefCounted
static func key(game: Node, code: int) -> void:
 if game.intro.visible:
  game.intro.skip()
  game.open_main_menu()
 var event:=InputEventKey.new()
 event.keycode=code
 event.pressed=true
 game._unhandled_input(event)
 event=event.duplicate()
 event.pressed=false
 game._unhandled_input(event)
static func start(game: Node) -> void:
 game.flow.root("title")
 key(game,KEY_ENTER)
 for i in range(5):key(game,KEY_DOWN)
 key(game,KEY_ENTER)
