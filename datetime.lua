--[[ OBS Studio datetime script

This script transforms a text source into a digital clock. The datetime format
is configurable and uses the same syntax than the Lua os.date() call.
]]

obs             = obslua
source_name     = ""
datetime_format = ""

activated       = false


-- Function to set the time text
function set_datetime_text(source, format)
	local text = os.date(format)
	local settings = obs.obs_data_create()

	obs.obs_data_set_string(settings, "text", text)
	obs.obs_source_update(source, settings)
	obs.obs_data_release(settings)
end

function timer_callback()
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		set_datetime_text(source, datetime_format)
		obs.obs_source_release(source)
	end
end

function activate(activating)
	if activated == activating then
		return
	end

	activated = activating

	if activating then
		obs.timer_add(timer_callback, 1000)
	else
		obs.timer_remove(timer_callback)
	end
end

-- Called when a source is activated/deactivated
function activate_signal(cd, activating)
	local source = obs.calldata_source(cd, "source")
	if source ~= nil then
		local name = obs.obs_source_get_name(source)
		if (name == source_name) then
			activate(activating)
		end
	end
end

function source_activated(cd)
	activate_signal(cd, true)
end

function source_deactivated(cd)
	activate_signal(cd, false)
end

function reset()
	activate(false)
	local source = obs.obs_get_source_by_name(source_name)
	if source ~= nil then
		local active = obs.obs_source_showing(source)
		obs.obs_source_release(source)
		activate(active)
	end
end

----------------------------------------------------------

function script_description()
	return "Sets a text source to act as a clock when the source is active.\
\
The datetime format can use the following tags:\
\
    %a	abbreviated weekday name (e.g., Wed)\
    %A	full weekday name (e.g., Wednesday)\
    %b	abbreviated month name (e.g., Sep)\
    %B	full month name (e.g., September)\
    %c	date and time (e.g., 09/16/98 23:48:10)\
    %d	day of the month (16) [01-31]\
    %H	hour, using a 24-hour clock (23) [00-23]\
    %I	hour, using a 12-hour clock (11) [01-12]\
    %M	minute (48) [00-59]\
    %m	month (09) [01-12]\
    %p	either \"am\" or \"pm\" (pm)\
    %S	second (10) [00-61]\
    %w	weekday (3) [0-6 = Sunday-Saturday]\
    %x	date (e.g., 09/16/98)\
    %X	time (e.g., 23:48:10)\
    %Y	full year (1998)\
    %y	two-digit year (98) [00-99]\
    %%	the character `%´"
end

function script_properties()
	local props = obs.obs_properties_create()

	obs.obs_properties_add_text(props, "format", "Datetime format", obs.OBS_TEXT_DEFAULT)

	local p = obs.obs_properties_add_list(props, "source", "Text Source", obs.OBS_COMBO_TYPE_EDITABLE, obs.OBS_COMBO_FORMAT_STRING)
	local sources = obs.obs_enum_sources()
	if sources ~= nil then
		for _, source in ipairs(sources) do
			source_id = obs.obs_source_get_id(source)
			if source_id == "text_gdiplus" or source_id == "text_ft2_source" then
				local name = obs.obs_source_get_name(source)
				obs.obs_property_list_add_string(p, name, name)
			end
		end
	end
	obs.source_list_release(sources)

	return props
end

function script_defaults(settings)
	obs.obs_data_set_default_string(settings, "format", "%X")
end

function script_update(settings)
	activate(false)

	source_name = obs.obs_data_get_string(settings, "source")
	datetime_format = obs.obs_data_get_string(settings, "format")

	reset()
end

function script_load(settings)
	local sh = obs.obs_get_signal_handler()
	obs.signal_handler_connect(sh, "source_show", source_activated)
	obs.signal_handler_connect(sh, "source_hide", source_deactivated)
end
