# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

# 
# 		width = 20
# 		hour = 100/11.0 - 0.05
# 		height = duration * hour
# 		left = days.index(a.upcase)*width
# 		top = hour*start
# 		"
# 		width: 20%;
# 		left: #{left}%;
# 		top: #{top}%;
# 		height: #{height}%;
# 		"

style = (day,start,duration,color) -> 
	width = 20
	hour = 100/11.0 - 0.05
	height = duration * hour
	left = days.indexOf(day.toUpperCase())*width
	top = hour*start
	{
		"width":"20%",
		"left":"#{left}%",
		"top":"#{top}%",
		"height":"#{height}%",
		"display":"block",
		"background-color":color
	}

exists_conflict = (c1, c2) ->
	((c1.start_time >= c2.start_time && c1.start_time <= c2.end_time) || 
	(c1.end_time >= c2.start_time && c1.end_time <= c2.end_time))

days = ["M", "T", "W", "R", "F"]
color = 0
colors = ["#FE9B00", "#17B9FA", "#1BCF11", "#672357", "#CCEBAC", "#187697", "#5369B5"]
courses = []

root = exports ? this
root.add_course = (start,duration,obj,direct) ->
	for day in obj.days.split("")
		s = style(day,start,duration,colors[color])
		c = $("#template").clone().css(s).appendTo($('#courses'))
		c.find('#s-block-dept').html(obj.dept)
		c.find('#s-block-cnum').html(obj.num)
		c.find('#s-block-time').html(obj.time)
		c.find('#s-block-title').html(obj.name)
		if direct
			c.attr("onclick":"$('#search-input').val('#{obj.dept} #{obj.num}'); $('#form').submit(); return false;")
		else
			c.data("content",obj.popover_content)
			c.data("title",obj.popover_title)
	courses.push(obj)
	color += 1

conflicting_course = (obj) ->
	for course in courses
		if exists_conflict(obj, course) || exists_conflict(course, obj)
			return course
	return null

root.compute_conflicts = ->
	for btn in $('.add-course-btn.btn-primary')
		obj = $(btn).data('section')
		conflict = conflicting_course(obj)
		if conflict
			$(btn).removeClass('btn-primary').addClass('btn-danger')
			$(btn).html("Conflict with #{conflict.dept} #{conflict.num}")

