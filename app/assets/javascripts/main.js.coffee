# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

style = (day,start,duration,color) -> 
	width = 20
	hour = 100/11.0
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
	day_overlap = null
	if c1.days && c2.days
		day_overlap = c1.days.split("").map( (day) ->
			c2.days.indexOf(day) > -1
		).reduce ((a, b) -> a || b)
	if !day_overlap
		return false
	
	((c1.start_time >= c2.start_time && c1.start_time < c2.end_time) || 
	(c1.end_time > c2.start_time && c1.end_time <= c2.end_time))

days = ["M", "T", "W", "R", "F"]
color = 0
colors = ["#FE9B00", "#17B9FA", "#1BCF11", "#672357", "#187697", "#5369B5"]
courses = []

s_id = "1"
secret = null

root = exports ? this

load_cookie = ->
	cookie = document.cookie
	if cookie
		match = cookie.match(/s_id=(\d+)&(.*?)(;| |$)/)
		if match
			s_id = match[1]
			secret = match[2]
			return true

	return false


set_cookie = ->
	expdate = new Date()
	expdate.setTime(expdate.getTime() + (24 * 60 * 60 * 365 * 4)) #4 yrs lol
	document.cookie = "s_id=#{s_id}&#{secret}; expires=#{expdate.toUTCString()};"

root.initialize = ->
	if load_cookie()
		console.log("loaded s=#{s_id}; secret=#{secret}")
	else
		s_id = "1"
		secret = "abc"
		set_cookie()
		console.log("load failed, writing cookie")

add_block = (obj) ->
	blx = []
	for day in obj.days.split("")
		s = style(day,obj.time_in_hours-10,obj.duration,colors[color % colors.length])
		c = $("#template").clone().addClass("b-#{obj.crn}").css(s).appendTo($('#courses'))
		c.find('#s-block-dept').html(obj.dept)
		c.find('#s-block-cnum').html(obj.num)
		c.find('#s-block-time').html(obj.time)
		c.find('#s-block-title').html(obj.name)
		blx.push(c)
	$(".b-#{obj.crn}")

ajax = (obj, action) -> 
	$.post("schedule/#{s_id}/#{action}", {"crn":obj.crn, "secret":secret}, ->
		console.log("ajax complete")
	)

root.add_course = (obj,popover, post) ->
	c = add_block(obj)
	if !popover
		c.attr("onclick":"$('#search-input').val('#{obj.dept} #{obj.num}'); $('#form').submit(); return false;")
	else
		c.data("content",obj.popover_content)
		c.data("title",obj.popover_title)
	courses.push(obj)
	color += 1

	if post
		ajax(obj, "add")

conflicting_course = (obj) ->
	a = []
	for course in courses
		if obj.crn == course.crn
			return null
		if exists_conflict(obj, course) || exists_conflict(course, obj)
			a.push(course)
	return a

remove_section_obj = (obj) ->
	$(".b-#{obj.crn}").remove()
	for course, i in courses
		if course.crn == obj.crn
			courses.splice(i,1)
			break

	ajax(obj, "delete")


root.remove_section = (btn) ->
	obj = $(btn).data('section')
	if (obj)
		remove_section_obj(obj)
		compute_buttons()

root.add_section = (btn) ->
	obj = $(btn).data('section')
	add_course(obj, false, true)
	compute_buttons()

root.undo_section = (btn) ->
	obj = $(btn).data('section')
	for conf in conflicting_course(obj)
		remove_section_obj(conf)

	add_section(btn)
	$(btn).remove()

root.conflict_section = (btn) ->
	obj = $(btn).data('section')
	for conf in conflicting_course(obj)
		remove_section_obj(conf)
		undo = $(btn).clone()
		undo.data("section",conf)
		undo.attr("id", "")
		undo.removeClass('btn-success').removeClass('btn-danger')
		undo.addClass('btn-warning').addClass('undo')
		undo.appendTo($(btn).parent())
		undo.html("Re-add #{conf.dept} #{conf.num}")
		undo.attr("onclick","undo_section(this);")

	add_section(btn)

format_btn = (btn, color, text, js) ->
	$(btn).removeClass('btn-primary').removeClass('btn-danger').removeClass('btn-success')
	$(btn).addClass(color)
	$(btn).find('.btn-title').html(text)
	$(btn).attr("onclick", "#{js}_section(this);")

root.compute_buttons = ->
	for btn in $('.add-course-btn').not('.disabled').not('.undo')
		obj = $(btn).data('section')
		conflict = conflicting_course(obj)
		if conflict == null
			format_btn(btn, "btn-success", "Remove Section", "remove")
		else if conflict.length > 0
			txt = conflict.map( (conf) ->
				"#{conf.dept} #{conf.num}"
			).join(" and ")
			format_btn(btn, "btn-danger", "Conflict with #{txt}", "conflict")
		else
			format_btn(btn, "btn-primary", "Add Section", "add")


root.hover = (btn) ->
	obj = $(btn).data('section')
	for course in courses
		if obj.crn == course.crn
			$(".b-#{obj.crn}").css("opacity",0.3)
			return
	c = add_block(obj)
	c.css("opacity",0.4)

root.unhover = (btn) ->
	obj = $(btn).data('section')
	for course in courses
		if obj.crn == course.crn
			$(".b-#{obj.crn}").css("opacity",0.75)
			return
	$(".b-#{obj.crn}").remove()
		
