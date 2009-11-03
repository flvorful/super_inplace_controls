require 'action_view'
require 'custom_helpers.rb'
require 'action_view/helpers/tag_helper'
require 'action_view/helpers/form_helper'
require 'action_view/helpers/javascript_helper'
# InPlaceControls - Do in-place-style editors with other form controls
module Flvorful
	module SuperInplaceControls

		include	 CustomHelpers
		# =MAIN
		# These controls were designed to be used with habtm & hm associations.  Just use the object and the foreign key as the attribute (see examples).  You can specify a chain of methods to use for the final display text (so you dont see the foreign key id)
		# 
		# Controller methods. Call just like the prototype helper method in_place_edit_for
		# 
		# =OPTIONS
		# <code>final_text</code> - this is an array of methods calls or a special symbol to be executed after the update<br>
		# <b>example</b>:<br> 
		# <code>in_place_edit_for( :prospect, "status_id", { :final_text => ["status", "title"] })</code>
		# This will chain the methods together to display the final text for  the update.  
		# The method call will look like: <code>object.status.title</code>
		# 
		# <b>special symbols</b>
		# <code>collection</code> - Use this as your final text if you want to use a checkbox collection on a HABTM or HM association.  This will call a method stack similar to: <code>object.collections.map { |e| e.title || e.name }.join(", ")</code><br>
		# <b>example</b>: <code>in_place_edit_for :product, :category_ids, {:final_text => :collection }</code>
		# 
		# <code>highlight_endcolor</code> - the end color for the "highlight" visual effect.<br> 
		# example: <code>in_place_edit_for( :prospect, "status_id", { :final_text => ["status", "title"], highlight_endcolor => "'#ffffff'" })</code>
		# 
		# <code>highlight_startcolor</code> - the start color for the "highlight" visual effect.<br> 
		# example: <code>in_place_edit_for( :prospect, "status_id", { :final_text => ["status", "title"], :highlight_startcolor => "'#ffffff'" })</code>
		# 
		# <code>error_messages</code> - the error messages div that errors will be put into.  defaults to error_messages<br>
		# <b>example:</b> <code>in_place_edit_for( :prospect, "status_id", { :error_messages => "my_error_div", :highlight_startcolor => "'#ffffff'" })</code>
		# 
		# <code>error_visual_effect</code> - The visual effect to use for displaying your error_message div. Defaults to :slide_down. <br>
		# example: <code>in_place_edit_for( :prospect, "status_id", { :error_visual_effect => :appear })</code>
		# 
		# =TODO
		# <code>final_text_operation</code> - this is a helper method that you want to call once the final_text is generated<br>
		# example: <code>in_place_edit_for( :prospect, "status_id", { :final_text => ["status", "title"] }, { :final_text_operation => ["truncate", 30] })</code>
		# This will call truncate on the final_text and pass in 30 as the argument.
		# Everything after the first argument (the method to call) is sent as an argument to the method. The method call is similar to: truncate(, 30)
		# 
		# 

		module ControllerMethods
			
			def in_place_edit_for(object, attribute, options = {}) 
				define_method("set_#{object}_#{attribute}") do
					setup_inplace_object(object, attribute, options)
					if @item.update_attributes(attribute => params[object][attribute])
						set_final_text(object, attribute, options)
						standard_inplace_render
					else
						inplace_error_render
					end
				end
			end

			def jquery_enabled?
				ActionView::Helpers::PrototypeHelper.const_defined?("JQUERY_VAR")
			end
			
		end


		module InstanceMethods
			include ActionView::Helpers::TagHelper
			def self.included(receiver)
				
			end
			
			def colorize(hex_code)
				jquery_enabled? ? "#{hex_code}" : hex_code
			end

			def jquery_enabled?
				ActionView::Helpers::PrototypeHelper.const_defined?("JQUERY_VAR")
			end

			def setup_inplace_object(object, attribute, options)
				@item = object.to_s.camelize.constantize.find(params[:id])
				@id_string = "#{object}_#{attribute}_#{@item.id}"
				@field_id = "#{object}_#{attribute}"
				@error_messages = options[:error_messages] || "error_messages"
				@highlight_endcolor = colorize(options[:highlight_endcolor] || "#ffffff")
				@highlight_startcolor = colorize(options[:highlight_startcolor] || "#ffff99")
				@error_visual_effect = options[:error_visual_effect] || :slide_down
			end

			def set_final_text(object, attribute, options)
				unless options[:final_text].nil?
					if options[:final_text] == :collection
						@final_text = @item.send(attribute.to_s.gsub("_ids", "").pluralize).map do |e| 
							e.title || e.name 
						end.join(", ")
					else
						methods = options[:final_text]
						@final_text = methods.inject(@item) { |sum_of_methods, meth| sum_of_methods = sum_of_methods.send(meth)  }
					end
					@final_text
				else
					@final_text = @item.send(attribute).to_s
				end
				@final_text = ("&nbsp;" * 9) if @final_text.blank?
				@final_text
			end

			def render_errors_html
				ret = content_tag(:h2, "Errors")
				ret << content_tag(:ul, nil) do
					@item.errors.full_messages.map { |e| content_tag(:li, e) }
				end
			end

			def standard_inplace_render
				render :update do |page|
					page.replace_html "#{@id_string}", @final_text
					page.hide "#{@id_string}_form"
					check_for_error_messages(page) do |page|
						page.hide @error_messages
					end
					toggle_error_fields(:remove, page)
					page.visual_effect :highlight, "#{@id_string}", :duration => 0.5, :endcolor => "#{@highlight_endcolor}", :startcolor => "#{@highlight_startcolor}"
				end
			end

			def inplace_error_render
				unless @error_messages.blank?
					errors_html = render_errors_html
					render :update do |page|
						toggle_error_fields(:add, page)
						check_for_error_messages(page) do |page|
							page.replace_html @error_messages, errors_html
							page.visual_effect @error_visual_effect, @error_messages
						end
					end 
				else
					raise @item.errors.inspect
				end
			end
			
		end


		# These methods are mixed into the view as helpers.
		# Common options for the helpers:
		#   :action - the action to submit the change to
		#   :saving_text - text to show while the request is processing.  Default is "Saving..."
		#   :object - the object to create the control for, if other than an instance variable. (Useful for iterations.)
		#   :display_text - the text to be display before the update.  Used when you want to use an 
		#   								in_place control for an association field.  Defaults to method
		#   :br           - add a <br /> tag after the field and before the submit tag.  Defaults to 
		#                   false/nil
		module HelperMethods
			# Creates an "active" date select control that submits any changes to the server
			# using an in_place_edit-style action.
			# Extra Options:
			#   :time		- Allows users to select the Time as well as the date.  Defaults to false.
			# By default the value of the object's attribute will be selected, or blank.
			# Example:
			#   <%= in_place_date_select :product, :display_begin_date %>
			# Note*:  If you are using jQuery, you must have jquery-ui installed for the datepicker 
			#   			to function properly.  Otherwise, nothing will happen.

			def in_place_date_select(object, method, options = {})
				options[:time] ||= false
				in_place_field(:date_select, object, method, options)
			end

			# Creates an "active" select box control that submits any changes to the server
			# using an in_place_edit-style action.
			# Extra Options:
			#   :choices 			- (required) An array of choices (see method "select")
			# By default the value of the object's attribute will be selected, or blank.
			# Example:
			#   <%= in_place_select :employee, :manager_id, :choices => Manager.find_all.map { |e| [e.name, e.id] } %>
			def in_place_select(object, method, options = {})
				check_for_choices(options)
				in_place_field(:select, object, method, options)
			end

			# Creates an "active" text field control that submits any changes to the server
			# using an in_place_edit-style action.
			# By default the value of the object's attribute will be filled in or blank.
			# Example:
			#   <%= in_place_text_field :product, :title %>
			def in_place_text_field(object, method, options = {})
				in_place_field(:text_field, object, method, options)
			end

			# Creates an "active" text area control that submits any changes to the server
			# using an in_place_edit-style action.
			# By default the value of the object's attribute will be filled in or blank.
			# Example:
			#   <%= in_place_text_area :product, :description %>
			def in_place_text_area(object, method, options = {})
				in_place_field(:text_area, object, method, options)
			end

			# Creates an "active" collection of checkbox controls that submits any changes to the server
			# using an in_place_edit-style action.
			# Extra Options:
			#   :choices 			- (required) An array of choices (see method "select")
			# By default the value of the object's attribute will be selected, or blank.
			# Example:
			#   <%= in_place_check_box_collection :product, :category_ids, :choices => Category.find(:all).map { |e| [e.id, e.title] } %>
			def in_place_check_box_collection(object, method, options = {})
				check_for_choices(options)
				options[:display_text] = :collection
				in_place_field(:check_box, object, method, options)
			end

			# Creates an "active" collection of radio controls that submits any changes to the server
			# using an in_place_edit-style action.
			# Extra Options:
			#   :choices 			- (required) An array of choices (see method "select")
			#   :columns 			- breaks up the collection into :columns number of columns
			# By default the value of the object's attribute will be selected, or blank.
			# Example:
			#   <%= in_place_radio_collection :product, :price, :choices => %w(199 299 399 499 599 699 799 899 999).map { |e| [e, e] } %>
			def in_place_radio_collection(object, method, options = {})
				check_for_choices(options)
				in_place_field(:radio, object, method, options)
			end

			# Creates an div container for error_messages
			def inplace_error_div(div_id = "error_messages", div_class = "error_messages")
				content_tag(:div, "", :id => div_id, :class => div_class, :style => "display:none")
			end

			
			def jquery_calendar_picker( object_name, method_name, options )
				ret = text_field(object_name, method_name, options )
				ret << javascript_tag do
					update_page do |page|
						page << "if (jQuery.isFunction(jQuery.fn.datepicker)) { jQuery('.inplace_date_select').datepicker() }"
					end
				end
			end
			
			
			# helpers for render
			def toggle_error_fields(dir, page)
				page.select("##{@id_string}_form ##{@field_id}").map do |e| 
					dir == :add ? e.add_class_name("fieldWithError") : e.remove_class_name("fieldWithError") 
				end
				page.show(dir == :add ? "#{@id_string}_form" : "#{@id_string}")
			end
			
			def check_for_error_messages(page)
				page << "if (document.getElementById('#{@error_messages}') != null) {"
				yield page
				page << "}"
			end


			protected

			def jquery_enabled?
				ActionView::Helpers::PrototypeHelper.const_defined?("JQUERY_VAR")
			end


			def check_for_choices(options)
				raise ArgumentError, "Missing choices for select! Specify options[:choices] for in_place_select" if options[:choices].nil?
			end

			def in_place_field(field_type, object, method, options)
				object_name = object.to_s
				method_name = method.to_s
				@object = self.instance_variable_get("@#{object}") || options[:object] 
				display_text = set_display_text(@object, method_name, options)
				ret =  html_for_inplace_display(object_name, method_name, @object, display_text)
				ret << form_for_inplace_display(object_name, method_name, field_type, @object, options)
			end

			def set_blank_text(text, number_of_spaces = 7)
				text = blank_text(number_of_spaces) if text.blank?
				text
			end
			
			def blank_text(number_of_spaces = 7)
				blank = "&nbsp;" * number_of_spaces
			end

			def set_display_text(object, attribute, options)
				display_text = ""
				if options[:display_text] == :collection
					display_text = object.send(attribute.to_s.gsub("_ids", "").pluralize).map do |e| 
						e.title || e.name 
					end.join(", ") 
				else
					display_text = options[:display_text] || object.send(attribute)
				end
				h display_text
			end

			def id_string_for(object_name, method_name, object)
				"#{object_name}_#{method_name}_#{object.id}"
			end

			def html_for_inplace_display(object_name, method_name, object, display_text)
				id_string = id_string_for(object_name, method_name, object)
				content_tag(:span, 	display_text, 
				:onclick => update_page do |page|
					page.hide "#{id_string}"
					page.show "#{id_string }_form"
				end, 
				:onmouseover => visual_effect(:highlight, id_string), 
				:title => "Click to Edit", 
				:id => id_string ,
				:class => "inplace_span #{"empty_inplace" if display_text.blank?}" 
				)


			end

			def form_for_inplace_display(object_name, method_name, input_type, object, opts)
				retval = ""
				id_string = id_string_for(object_name, method_name, object)
				set_method = opts[:action] || "set_#{object_name}_#{method_name}"
				save_button_text = opts[:save_button_text] || "OK"
				loader_message = opts[:saving_text] || "Saving..."
				retval << draw_form(set_method, object, id_string, opts)

				retval << field_for_inplace_editing(object_name, method_name, object, opts, input_type )
				retval << draw_break(opts)
				retval << submit_tag( save_button_text, :class => "inplace_submit")
				retval << cancel_link(id_string)
				retval << end_form
				retval << invisible_loader( loader_message, "loader_#{id_string}", "inplace_loader")
				retval << content_tag(:br)
			end
			
			def cancel_link(id_string)
				link_to_function( "Cancel", update_page do |page|
					page.show "#{id_string}"
					page.hide "#{id_string}_form"
				end, {:class => "inplace_cancel" })
			end
			
			def draw_break(opts = {})
				 opts[:br] ? content_tag(:br) : ""
			end
			
			def end_form
				"</form>"
			end
			
			def draw_form(set_method, object, id_string, opts = {})
				form_remote_tag(:url => { :action => set_method, :id => object.id },
				:method => opts[:http_method] || :post,
				:loading => update_page do |page|
					page.show "loader_#{id_string}"
					page.hide "#{id_string}_form"
				end,
				:complete => update_page do |page|
					page.hide "loader_#{id_string}"
				end,
				:html => {:class => "in_place_editor_form", :id => "#{id_string}_form", :style => "display:none" } )
			end

			def field_for_inplace_editing(object_name, method_name,  object, options , input_type)
				options[:class] = "inplace_#{input_type}"
				htm_opts = {:class => options[:class] }
				case input_type
				when :text_field
					text_field(object_name, method_name, options )
				when :text_area
					text_area(object_name, method_name, options )
				when :select
					select(object_name, method_name,  options[:choices], options, htm_opts )
				when :check_box
					options[:label_class] = "inplace_#{input_type}_label"
					checkbox_collection(object_name, method_name, object,  options[:choices], options )
				when :radio
					options[:label_class] = "inplace_#{input_type}_label"
					radio_collection(object_name, method_name, object,  options[:choices], options )
				when :date_select
					jquery_enabled? ? 
					jquery_calendar_picker( object_name, method_name, options ) : 
					calendar_date_select( object_name, method_name, options)
				end
			end


		end
	end
end

