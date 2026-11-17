class_name StoryDialogue
extends RefCounted
signal completed(id: String)
const FONT=preload("res://assets/ui/arcade/arcade.fnt")
const CONTENT_WIDTH=278
const LINES_PER_PAGE=2
const CHARACTERS_PER_BEAT=32.0
var definitions: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/story/dialogue.json"))
var queue: Array[Dictionary]=[]
var held: bool=false
var pending: bool=false
var next_branch: String=""
var pages: Array[String]=[]
var page: int=0
var page_started: float=0
var sampled_beat: float=0
var forced_reveal: bool=false
func active() -> bool:return not queue.is_empty()
func line() -> Dictionary:return queue[0] if active() else {}
static func wrapped_lines(value: String, width: float=CONTENT_WIDTH) -> Array[String]:
 var result: Array[String]=[]
 var current: String=""
 for word in value.split(" "):
  var candidate: String=word if current.is_empty() else current+" "+word
  if FONT.get_string_size(candidate.to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,8).x>width and not current.is_empty():
   result.append(current)
   current=word
  else:current=candidate
 if not current.is_empty():result.append(current)
 return result
func sync(beat: float) -> void:sampled_beat=beat
func prepare_page() -> void:
 pages.clear()
 var lines:=wrapped_lines(str(line().get("text","")))
 for i in range(0,lines.size(),LINES_PER_PAGE):
  var group: Array[String]=[]
  for j in range(i,mini(i+LINES_PER_PAGE,lines.size())):group.append(lines[j])
  pages.append("\n".join(group))
 page=0
 page_started=sampled_beat
 forced_reveal=false
func page_text() -> String:return pages[page] if active() and not pages.is_empty() else ""
func revealed_count() -> int:
 return page_text().length() if forced_reveal else mini(page_text().length(),int(maxf(0,sampled_beat-page_started)*CHARACTERS_PER_BEAT))
func visible_text() -> String:return page_text().left(revealed_count())
func is_revealed() -> bool:return revealed_count()>=page_text().length()
func begin(id: String, indices: Array=[]) -> void:
 var was_empty:=not active()
 var lines: Array=definitions[id]
 for i in range(lines.size()):
  if not indices.is_empty() and not indices.has(i):continue
  if lines[i].get("type","")!="speech":continue
  var entry: Dictionary=lines[i].duplicate()
  entry.id=id
  entry.sequence_index=i
  entry.last=i==(indices.back() if not indices.is_empty() else lines.size()-1)
  queue.append(entry)
 if was_empty:prepare_page()
func press(pressed: bool) -> void:
 if pressed and not held and active():pending=true
 held=pressed
func on_subdivision() -> void:
 if not pending or not active():return
 pending=false
 if not is_revealed():
  forced_reveal=true
  return
 if page+1<pages.size():
  page+=1
  page_started=sampled_beat
  forced_reveal=false
  return
 var entry: Dictionary=queue.pop_front()
 if active():prepare_page()
 if entry.last:completed.emit(entry.id)
func clear() -> void:
 queue.clear()
 pages.clear()
 page=0
 held=false
 pending=false
 forced_reveal=false
