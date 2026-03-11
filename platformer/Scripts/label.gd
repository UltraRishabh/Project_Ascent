extends Label

## This script displays a comprehensive set of performance metrics for Godot 4.
## Attach it to a Label node in your scene to see the stats in real-time.
#
#func _process(delta):
#
	#var fps = Performance.get_monitor(Performance.TIME_FPS)
	#var process_time = Performance.get_monitor(Performance.TIME_PROCESS) * 1000
	#var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000
#
	#var current_mem = OS.get_static_memory_usage() / 1024.0 / 1024.0
	#var peak_mem = OS.get_static_memory_peak_usage() / 1024.0 / 1024.0
#
	#var resource_count = Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)
#
	## -- FORMAT THE FINAL TEXT --
	##text = """
	##FPS: %s
	##[CPU]
	##Process: %.2f ms
	##Physics: %.2f ms
	##[Memory]
	##Current: %.2f MB
	##Peak: %.2f MB
	##[Scene]
	##Resources: %s
	##""" % [
		##fps,
		##process_time, physics_time,
		##current_mem, peak_mem,
		##resource_count,
	##]
