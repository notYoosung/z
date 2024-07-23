local modname = minetest.get_current_modname()
local mod_path = minetest.get_modpath(modname) .. "/zoonami"

-- Makes formspec code easier to read and write

-- Local namespace
local fs = {}

function fs.animation(x, y, width, height, field_name, file_name, frame_count, frame_duration, frame_start, zoom)
	zoom = zoom or 1
	return "animated_image["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..field_name..";"..file_name..";"..frame_count..";"..frame_duration..";"..frame_start.."]"
end

function fs.background(x, y, width, height, file_name, zoom)
	zoom = zoom or 1
	return "background["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..file_name.."]"
end

function fs.background9(x, y, width, height, file_name, auto_clip, middle, zoom)
	zoom = zoom or 1
	return "background9["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..file_name..";"..auto_clip..";"..middle.."]"
end

function fs.backpack_header(left_page, right_page, label, zoom)
	zoom = zoom or 1
	return fs.font_style("button,image_button,tooltip,label,field,textarea", "mono,bold", 16, "#000000", zoom)..
		fs.background(0, 0, 9, 9, "zoonami_backpack_background.png", zoom)..
		fs.button(2.145, 0.4, 0.755, 0.51, left_page, "◄", zoom)..
		fs.button(6.12, 0.4, 0.755, 0.51, right_page, "►", zoom)..
		fs.button_style(2, 8)..
		fs.button(3, 0.4, 3, 0.51, "label", label, zoom)..
		fs.button_style(1, 8)..
		fs.box(3, 0.4, 3, 0.51, "#00000000", zoom)
end

function fs.box(x, y, width, height, color, zoom)
	zoom = zoom or 1
	return "box["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..color.."]"
end

function fs.button(x, y, width, height, field_name, text, zoom)
	zoom = zoom or 1
	return "button["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..field_name..";"..text.."]"
end

function fs.button_style(button_id, slice_size)
	return "style_type[button;bgimg=zoonami_button_"..button_id..".png;bgimg_middle="..slice_size..";padding=-"..slice_size..";border=false]" ..
		"style_type[button:pressed;bgimg=zoonami_button_"..button_id.."_pressed.png]"
end

function fs.dialogue(text, zoom)
	zoom = zoom or 1
	return fs.box(0, 5, 6, 1, "#000000FF", zoom)..
		fs.box(0.1, 5.1, 5.8, 0.8, "#F5F5F5FF", zoom)..
		fs.textarea(0.15, 5.15, 5.85, 0.85, text, zoom)
end

function fs.field(x, y, width, height, name, label, default_value, zoom)
	zoom = zoom or 1
	return "field["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..name..";"..label..";"..default_value.."]"
end

function fs.folder_button(x, y, width, height, file_name, field_name, text, zoom)
	zoom = zoom or 1
	return "image_button["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..file_name..".png;"..field_name..";"..text..";false;false]"
end

function fs.font_style(elements, font_type, font_size, font_color, zoom)
	zoom = zoom or 1
	font_size = type(font_size) == "number" and font_size * zoom or font_size
	return "style_type["..elements..";font="..font_type..";font_size="..font_size..";textcolor="..font_color.."]"
end

function fs.header(width, height, fixed_size, bgcolor, zoom)
	zoom = zoom or 1
	return "formspec_version[3]"..
		"size["..zoom*width..","..zoom*height..","..fixed_size.."]"..
		"no_prepend[true]"..
		"bgcolor["..bgcolor.."]"
end

function fs.image(x, y, width, height, file_name, zoom)
	zoom = zoom or 1
	return "image["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..file_name.."]"
end

function fs.image_button(x, y, width, height, file_name, field_name, text, zoom)
	zoom = zoom or 1
	return "image_button["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..file_name..".png;"..field_name..";"..text..";false;false;"..file_name.."_pressed.png]"
end

function fs.image_button_style(button_id, slice_size)
	return "style_type[image_button;bgimg=zoonami_button_"..button_id..".png;bgimg_middle="..slice_size..";padding=-"..slice_size..";border=false]" ..
		"style_type[image_button:pressed;bgimg=zoonami_button_"..button_id.."_pressed.png]"
end

function fs.item_image_button(x, y, width, height, item_name, field_name, zoom)
	zoom = zoom or 1
	return "item_image_button["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..item_name.." 1;"..field_name..";]"
end

function fs.label(x, y, text, zoom)
	zoom = zoom or 1
	return "label["..zoom*x..","..zoom*y..";"..text.."]"
end

function fs.list(inventory_location, list_name, x, y, width, height, starting_index, zoom)
	zoom = zoom or 1
	return "list["..inventory_location..";"..list_name..";"..zoom*x..","..zoom*y..";"..width..","..height..";"..starting_index.."]"
end

function fs.list_colors(slot_bg, slot_bg_hover, slot_border, tooltip_bg, tooltip_font)
	return "listcolors["..slot_bg..";"..slot_bg_hover..";"..slot_border..";"..tooltip_bg..";"..tooltip_font.."]"
end

function fs.list_style(noclip, size, spacing, zoom)
	zoom = zoom or 1
	return "style_type[list;noclip="..noclip..";size="..zoom*size..";spacing="..zoom*spacing.."]"
end

function fs.listring(inventory_location, list_name)
	return "listring["..inventory_location..";"..list_name.."]"
end

function fs.menu_image_button(x, y, width, height, button_type_id, field_name, text, zoom)
	zoom = zoom or 1
	return "image_button["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";zoonami_menu_button"..button_type_id..".png;"..field_name..";"..text..";false;false;zoonami_menu_button"..button_type_id.."_pressed.png]"
end

function fs.monster_button(x, y, width, height, file_name, field_name, zoom)
	zoom = zoom or 1
	return "image_button["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..file_name..".png;"..field_name..";;false;false]"
end

function fs.scrollbar(x, y, width, height, orientation, field_name, value, zoom)
	zoom = zoom or 1
	return "scrollbar["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..orientation..";"..field_name..";"..value.."]"
end

function fs.scroll_container(x, y, width, height, field_name, orientation, scroll_factor, zoom)
	zoom = zoom or 1
	return "scroll_container["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";"..field_name..";"..orientation..";"..zoom*scroll_factor.."]"
end

function fs.scroll_container_end(minimum, maximum, thumbsize)
	return "scroll_container_end[]"..
		"scrollbaroptions[min="..minimum..";max="..maximum..";thumbsize="..thumbsize.."]"
end

function fs.textarea(x, y, width, height, text, zoom)
	zoom = zoom or 1
	return "textarea["..zoom*x..","..zoom*y..";"..zoom*width..","..zoom*height..";;;"..text.."]"
end

function fs.tooltip(field_name, text, background_color, text_color)
	return "tooltip["..field_name..";"..text..";"..background_color..";"..text_color.."]"
end

return fs
