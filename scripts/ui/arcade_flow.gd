class_name ArcadeFlow
extends RefCounted
var game: Node2D
var view:=ArcadeFrontEnd.new()
var stack: Array[String]=[]
func setup(owner: Node2D) -> void:
 game=owner
 view.activated.connect(command)
 view.adjusted.connect(adjust)
func active() -> bool:return game.mode=="menu" or game.paused or game.mode=="match_win"
func open(page: String) -> void:
 stack.append(view.page)
 view.open(page)
 refresh()
func root(page: String) -> void:
 stack.clear()
 view.open(page)
 refresh()
func item(label: String, action: String) -> Dictionary:return {"label":label,"command":action}
func option(label: String,key: String,value: String) -> Dictionary:return {"label":label,"key":key,"value":value}
func refresh() -> void:
 view.visible=active()
 if not view.visible:return
 var p: Dictionary=game.preferences.values
 var rows: Array[Dictionary]=[]
 var title: String="STICKS N LICKS"
 var sub: String="RHYTHM. SPACING. ONE MORE BOUT."
 match view.page:
  "title":rows=[item("START GAME","setup"),item("OPTIONS","options"),item("HOW TO PLAY","help"),item("QUIT GAME","quit")]
  "setup":
   title="MATCH SETUP"
   sub="FIRST TO %d ROUND WINS" % (int(game.settings.get("match_best_of",3))/2+1)
   var stage_name: String="RANDOM"
   for stage in game.stage.entries:
    if stage.id==game.stage_preference:stage_name=stage.name
   rows=[option("MODE","game_mode","PLAYER VS CPU" if game.game_mode=="cpu" else "PLAYER VS PLAYER"),option("CPU","difficulty",game.cpu_difficulty if game.game_mode=="cpu" else "--"),option("MATCH","best_of","BEST OF %d" % int(game.settings.get("match_best_of",3))),option("TEMPO","bpm","%d BPM" % game.selected_bpm),option("STAGE","stage",stage_name),item("START BOUT","start"),item("BACK","back")]
  "options":
   title="OPTIONS"
   sub="MAKE YOURSELF AT HOME"
   rows=[item("AUDIO","audio"),item("DISPLAY","display"),item("GAMEPLAY","gameplay"),item("RESET DEFAULTS","defaults"),item("BACK","back")]
  "audio":
   title="AUDIO"
   sub="VOLUME / SOUND"
   rows=[option("MASTER","master","%d%%" % p.master),option("MUSIC","music","%d%%" % p.music),option("SOUND EFFECTS","sfx","%d%%" % p.sfx),option("MUSIC","music_on","ON" if p.music_on else "OFF"),option("SOUND EFFECTS","sfx_on","ON" if p.sfx_on else "OFF"),item("BACK","back")]
  "display":
   title="DISPLAY"
   sub="CRISP PIXELS. CLEAN EDGES."
   rows=[option("MODE","fullscreen","FULLSCREEN" if p.fullscreen else "WINDOWED"),option("INTEGER SCALE","integer_scale","ON" if p.integer_scale else "OFF"),item("BACK","back")]
  "gameplay":
   title="GAMEPLAY"
   sub="KEEP YOUR EYES ON THE BEAT"
   rows=[option("STEP FEEDBACK","timing_feedback","ON" if p.timing_feedback else "OFF"),item("CONTROL REFERENCE","help"),item("BACK","back")]
  "help":
   title="HOW TO PLAY"
   sub=""
  "pause":
   title="BOUT PAUSED"
   sub="THE BEAT WILL WAIT"
   rows=[item("RESUME","resume"),item("RESTART MATCH","restart"),item("OPTIONS","options"),item("HOW TO PLAY","help"),item("MAIN MENU","title")]
  "result":
   title=("YOU WIN!" if game.match_progress.winner==0 else "YOU LOSE!") if game.game_mode=="cpu" else ("RED WINS!" if game.match_progress.winner==0 else "BLUE WINS!")
   rows=[item("REMATCH","rematch"),item("MATCH SETUP","setup"),item("MAIN MENU","title")]
 view.present(title,rows,sub)
func command(action: String) -> void:
 if action=="nav":
  game.audio.emit_event("menu_navigate")
  return
 game.audio.emit_event("menu_back" if action in ["back","tutorial_exit","title"] else "menu_confirm")
 match action:
  "setup":
   if game.mode=="match_win":game.return_to_title()
   game.apply_preferences(true)
   open("setup")
  "start","rematch","restart":
   if game.paused:game.set_paused(false)
   game.begin()
  "resume":game.set_paused(false)
  "title":game.return_to_title()
  "tutorial_exit":
   if not stack.is_empty():view.open(stack.pop_back())
   else:view.open("pause" if game.paused else "title")
  "options","audio","display","gameplay","help":open(action)
  "defaults":
   game.preferences.values=UserPreferences.DEFAULTS.duplicate(true)
   game.apply_preferences(game.mode=="menu")
   game.preferences.save_values()
  "quit":game.get_tree().quit()
  "back":
   if view.page=="pause":game.set_paused(false)
   elif view.page=="result":game.return_to_title()
   elif not stack.is_empty():view.open(stack.pop_back())
   else:view.open("title")
 refresh()
func adjust(key: String,direction: int) -> void:
 var p: Dictionary=game.preferences.values
 var choices: Dictionary={"game_mode":["cpu","pvp"],"difficulty":["easy","normal","hard"],"best_of":[3,5,7],"bpm":[120,140,160],"stage":["random"]}
 for stage in game.stage.entries:choices.stage.append(stage.id)
 if key=="difficulty" and game.game_mode!="cpu":return
 if choices.has(key):
  var values: Array=choices[key]
  p[key]=values[posmod(values.find(p[key])+direction,values.size())]
 elif key in ["master","music","sfx"]:p[key]=clampi(int(p[key])+direction*10,0,100)
 elif typeof(p.get(key))==TYPE_BOOL:p[key]=not p[key]
 game.apply_preferences(game.mode=="menu")
 game.preferences.save_values()
 refresh()
