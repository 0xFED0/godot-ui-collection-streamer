tool
extends Reference

class_name CollectionStreamer

const VISIBLE_RESERVED_LINES   :int = 0
const INVISIBLE_RESERVED_LINES :int = 0
const ALL_RESERVED_LINES : = VISIBLE_RESERVED_LINES + INVISIBLE_RESERVED_LINES

# INPUT:
#	UiState = {
#	    shape = {
#	        line_stride :float
#	        columns :int
#	        items_count :int
#	    }
#	    frame = {
#	        height :float
#	        pos :float
#	        prev_visible_range = [start:int, end:int]
#	    }
#	}
# OUTPUT:
#	Result = {
#	    spaces = [top:float, bottom:float]
#	    visible_range = [start:int, end:int]
#	    full_range    = [start:int, end:int]
#	}


static func calc_line_stride(container :Control, prototype :Control) -> float:
	var separation = container.get_constant('vseparation')
	if not (separation is int):
		separation = container.get_constant('separation')
	if not (separation is int):
		separation = 0.0
	return prototype.rect_size.y + float(separation)


const _RESULT : = {} # to not realloc each time

static func update_frame(ui_state, forced :bool = false): # (UiState) -> Result
	var result : = _RESULT
	if is_collection_empty(ui_state):
		result.spaces        = [0, 0]
		result.visible_range = [0, -1]
		result.full_range    = [0, -1]
		return result
	
	if not(forced or is_beyond_safe_frame(ui_state)):
		return null
	
	var visible_lines : = _calc_visible_range(ui_state.frame, ui_state.shape)
	var all_lines     : = _calc_range_with_reserves(visible_lines, ui_state.shape)
	
	result.spaces        = _calc_spaces(all_lines, ui_state.shape)
	result.visible_range = _from_lines(visible_lines, ui_state.shape)
	result.full_range    = _from_lines(all_lines, ui_state.shape)
	return result


static func is_collection_empty(state) -> bool:
	return state.shape.items_count < 1


static func is_beyond_safe_frame(state) -> bool:
	var lines : = _to_lines(state.frame.get('prev_visible_range',[0,0]), state.shape)
	lines[0] -= VISIBLE_RESERVED_LINES
	lines[1] += VISIBLE_RESERVED_LINES
	var prev_start  :float = _get_line_offset(lines.front(),    state.shape)
	var prev_end    :float = _get_line_offset(lines.back() + 1, state.shape)
	var frame_start :float = state.frame.pos
	var frame_end   :float = state.frame.pos + state.frame.height
	return (frame_start < prev_start) or (frame_end > prev_end)


static func _calc_visible_range(frame, shape) -> Array:
	var start_line = _get_line_at_pos(frame.pos, shape)
	var end_line   = _get_line_at_pos(frame.pos + frame.height, shape)
	return _clamp_lines_range([start_line, end_line], shape)


static func _calc_range_with_reserves(rng :Array, shape) -> Array:
	var start_line = rng.front() - ALL_RESERVED_LINES
	var end_line   = rng.back()  + ALL_RESERVED_LINES
	return _clamp_lines_range([start_line, end_line], shape)


static func _calc_spaces(rng :Array, shape) -> Array:
	var top_space    : = _distance_between_lines(0, rng.front(), shape)
	var bottom_space : = _distance_between_lines(rng.back() + 1, _get_last_line(shape) + 1, shape)
	return [top_space, bottom_space]


static func _distance_between_lines(line1 :int, line2 :int, shape) -> float:
	var pos1 = _get_line_offset(line1, shape)
	var pos2 = _get_line_offset(line2, shape)
	return abs(pos2-pos1)


static func _clamp_lines_range(rng :Array, shape) -> Array:
	var first_line : = _get_first_idx(shape)
	var last_line  : = _get_last_line(shape)
	rng[0] = int(max(0, clamp(rng[0], first_line, last_line)))
	rng[1] = int(clamp(rng[1], first_line, last_line))
	return rng


static func _clamp_items_range(rng :Array, shape) -> Array:
	var first_item : = _get_first_idx(shape)
	var last_item  : = _get_last_item(shape)
	rng[0] = int(max(0, clamp(rng[0], first_item, last_item)))
	rng[1] = int(clamp(rng[1], first_item, last_item))
	return rng


static func _get_last_line(shape) -> int:
	return _line_from_idx(shape.items_count - 1, shape)


static func _get_last_item(shape) -> int:
	return int(shape.items_count - 1)


static func _get_first_idx(shape) -> int:
	return 0 if shape.items_count > 0 else -1


static func _from_lines(rng :Array, shape) -> Array:
	var start_idx : = _first_idx_in_line(rng.front(), shape)
	var end_idx   : = _last_idx_in_line (rng.back(), shape)
	return _clamp_items_range([start_idx, end_idx], shape)

static func _to_lines(rng :Array, shape) -> Array:
	var start_line : = _line_from_idx(rng.front(), shape)
	var end_line   : = _line_from_idx(rng.back(), shape)
	return _clamp_lines_range([start_line, end_line], shape)


static func _get_line_offset(line :int, shape) -> float:
	return line * shape.line_stride

static func _get_line_at_pos(pos :float, shape) -> int:
	return int(pos / shape.line_stride)


static func _line_from_idx(idx :int, shape) -> int:
	return int(idx / shape.columns) if idx >= 0 else -1

static func _first_idx_in_line(line :int, shape) -> int:
	return line * shape.columns

static func _last_idx_in_line(line :int, shape) -> int:
	return (line + 1) * shape.columns - 1

