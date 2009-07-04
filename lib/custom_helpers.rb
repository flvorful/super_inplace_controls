return if defined?(STATES)
class Object
  def proper_case
    to_s.humanize.split(/\s/).map { |e| e.capitalize }.join(" ")
  end

  def rubify
    to_s.downcase.gsub(/\W/, ' ').squeeze(' ').strip.gsub(' ', '_')
  end

  def rubify!
    replace rubify
  end
end
module Flvorful
  
  # These are some extra form helpers to help you clean up your views.  They add a label to the regular input field.
  # There are several extra options to help control the look of the label.
  # ==Options
  # <b>:human_name</b> - By default, the labeler will use the method as the label name.  You can change it to whatever you want by passing in this option. ie:
  #  text_field_with_label :product, :title, {:human_name => "Product Name"}
  #
  # <b>:required</b> - pass :required => true to add a "*" after the label to indicate a require field. ie:
  #  text_field_with_label :product, :title, {:required => true}
  #
  # <b>:br</b> - pass :br => false to remove the defaulted <br /> tag after the form control group. ie:
  #  text_field_with_label :product, :title, {:br => false}
  # will produce
  #  <label id="product_title_label" class="text_field_label" for="product_title">Title: </label>
  #  <input id="product_title" class="input_text_field" type="text" value="123" size="30" name="product[title]" input_type="text_field"/>
  # instead of
  #  <label id="product_title_label" class="text_field_label" for="product_title">Title: </label>
  #  <input id="product_title" class="input_text_field" type="text" value="123" size="30" name="product[title]" input_type="text_field"/>
  #  <br/>
  # used when you want to chain multiple form controls on one line by floating everything.
  #
  # <b>:break_after_label</b> - pass :break_after_label => true to add a "<br />" after the label so that the input field falls below the label instead of next to it. ie:
  #  text_field_with_label :product, :title, {:break_after_label => true}
  #
  module CustomHelpers
    
    STATES = [ 	
      ['Select a State', 'None'],
      ['Alabama', 'AL'], 
      ['Alaska', 'AK'],
      ['Arizona', 'AZ'],
      ['Arkansas', 'AR'], 
      ['California', 'CA'], 
      ['Colorado', 'CO'], 
      ['Connecticut', 'CT'], 
      ['Delaware', 'DE'], 
      ['District Of Columbia', 'DC'], 
      ['Florida', 'FL'],
      ['Georgia', 'GA'],
      ['Hawaii', 'HI'], 
      ['Idaho', 'ID'], 
      ['Illinois', 'IL'], 
      ['Indiana', 'IN'], 
      ['Iowa', 'IA'], 
      ['Kansas', 'KS'], 
      ['Kentucky', 'KY'], 
      ['Louisiana', 'LA'], 
      ['Maine', 'ME'], 
      ['Maryland', 'MD'], 
      ['Massachusetts', 'MA'], 
      ['Michigan', 'MI'], 
      ['Minnesota', 'MN'],
      ['Mississippi', 'MS'], 
      ['Missouri', 'MO'], 
      ['Montana', 'MT'], 
      ['Nebraska', 'NE'], 
      ['Nevada', 'NV'], 
      ['New Hampshire', 'NH'], 
      ['New Jersey', 'NJ'], 
      ['New Mexico', 'NM'], 
      ['New York', 'NY'], 
      ['North Carolina', 'NC'], 
      ['North Dakota', 'ND'], 
      ['Ohio', 'OH'], 
      ['Oklahoma', 'OK'], 
      ['Oregon', 'OR'], 
      ['Pennsylvania', 'PA'], 
      ['Rhode Island', 'RI'], 
      ['South Carolina', 'SC'], 
      ['South Dakota', 'SD'], 
      ['Tennessee', 'TN'], 
      ['Texas', 'TX'], 
      ['Utah', 'UT'], 
      ['Vermont', 'VT'], 
      ['Virginia', 'VA'], 
      ['Washington', 'WA'], 
      ['West Virginia', 'WV'], 
      ['Wisconsin', 'WI'], 
      ['Wyoming', 'WY']
    ]
    
    # creates a textfield control with a label mapped to the specified object/method combination
    def text_field_with_label(object_name, method, options = {})
      set_class_name(options, "text_field")
      set_input_type(options, "text_field")
      ret = create_label_field(object_name, method, options)
      ret << text_field( object_name, method, options)
      ret << add_break_to_form(options)
    end
    
    # creates a select control with a label mapped to the specified object/method combination
    def select_field_with_label(object_name, method, choices, options = {}, html_options = {})
      set_class_name(html_options, "select") if html_options[:class].blank?
      set_input_type(options, "select")
      ret = create_label_field(object_name, method, options)
      ret << select( object_name, method, choices, options, html_options)
      ret << add_break_to_form(options)
    end
    
    # creates a textarea control with a label mapped to the specified object/method combination
    def textarea_field_with_label(object_name, method, options = {})
      set_class_name(options, "textarea")
      set_input_type(options, "textarea")
      ret = create_label_field(object_name, method, options)
      ret << text_area( object_name, method, options)
      ret << add_break_to_form(options)
    end
    
    # creates a checkbox control with a label mapped to the specified object/method combination
    def checkbox_field_with_label(object_name, method, options = {})
      set_class_name(options, "checkbox")
      rad_options = options.dup
      rad_options.delete(:break_after_label)
      rad_options.delete(:human_name)
      options[:radio_label] = true
      set_input_type(options, "checkbox")
      ret = check_box(object_name, method, rad_options)
      ret << create_label_field(object_name, method, options)
      ret << add_break_to_form(options)

    end
    
    # creates a radio control with a label mapped to the specified object/method combination
    def radio_button_with_label(object_name, method, value, options = {})	
      rad_options = options.dup
      rad_options.delete(:br)
      set_class_name(rad_options, "radio")
      ret = radio_button( object_name, method, value, rad_options )
      options[:human_name] = options[:human_name] || value
      options[:radio_label] = true
      options[:radio_value] = value
      set_input_type(options, "radio")
      ret << create_label_field(object_name, method, options)
      ret << add_break_to_form(options)
    end
    
    
    # Like country_select, but for US States
    def state_select(object, method)
      select(object, method, STATES)
    end
    
    # creates a series of checkbox controls and labels with the specified collection
    def checkbox_collection(object, method, instance, collection, opts = {})
      css_class = opts[:css_class] || "inplace_checkbox"
      columns = opts[:columns] || 1

      m2m = instance.send("#{method}") 
      name_string = "#{object}[#{method}][]"

      htm_class = opts.delete(:label_class)
      htm_class ||= "checkbox_collection_label"
      collection.map do |k, v|
        id_string = "#{object}_#{method}_#{k}"
        tag_options = {
          :type => "checkbox", 
          :name => name_string,
          :id => id_string,
          :value => k,
          :class => css_class
        }
        title = opts[:title] || v rescue "No Title"
        tag_options[:checked] = "checked" if m2m.respond_to?(:collect) && m2m.include?(k)
        final_out = tag(:input, tag_options) + content_tag(:label, title, :for => id_string, :class => htm_class )
        str = []

        columns.to_i.times do |x|
          str << " "
        end unless columns == 1
        str <<  tag(:br)
        unless columns == 1
          final_out << cycle("", str) 
        else
          final_out << tag(:br)
        end
        final_out
      end.join("\n") + tag(:br)
    end
    
    
    # creates a series of radio controls and labels with the specified collection
    def radio_collection(object, method, instance, collection, options = {})
      ret = ""
      columns = options[:columns] || 1

      label_class ||= options.delete(:label_class)
      label_class ||= "radio_collection_label"
      options[:class] ||= "input_radio radio_collection_input"
      collection.each do |element| 
        ret << radio_button(object, method, element[1], options)
        ret << content_tag(:label, element.first, {:for => "#{object}_#{method}_#{element[1]}", :class => label_class})
        str = []
        columns.to_i.times do |x|
          str << " "
        end unless columns == 1
        str <<  tag(:br)
        unless columns == 1
          ret << cycle("", str) 
        else
          ret << tag(:br)
        end
      end
      ret << tag(:br)
      ret
    end

    # A Quick invisible loader.  Creates a div container with an image tag.  Looks for an image named spinner.gif in /images
    # Can switch between 2 loaders (regular [spinner.gif] and white [spinner_white.gif])
    def invisible_loader(message = nil, div_id = "loader", class_name = "loader", color = "regular")
      spinner = case color
      when "regular"
        image_tag("spinner.gif")
      when "white"
        image_tag("spinner_white.gif")
      end

      content_tag(:div, :id => div_id, :class => class_name, :style => "display:none" ) do
        spinner + "&nbsp;&nbsp;" + content_tag(:span, message.to_s)
      end
    end
    
    
    protected
    def add_break_to_form(options)
      unless options[:br] == false && !options[:br].nil?
        ret = tag(:br)
      end
      ret || ""
    end
    
    def set_class_name(options, type)
      options.merge!({:class => "input_#{type}" })
    end
    
    def set_input_type(options, input_type)
      options[:input_type] = input_type
    end

    def create_label_field(object_name, method, options = {})
      human_name = options[:human_name] || method.proper_case.gsub(/url/i, "URL")
      id_string = "#{object_name.to_s.downcase}_#{method.to_s.downcase}"
      id_string = id_string + "_#{options[:radio_value].rubify}".gsub(/_$/, "") if options[:radio_label]
      label_id = id_string + "_" + "label"
      class_name = options[:input_type] + "_label"
      ret = content_tag(:label, :for => id_string, :id => label_id, :class => class_name) do
        "#{human_name}#{":" unless options[:radio_label]} #{"*" if options[:required] == true }"
      end
      ret << tag(:br) if options[:break_after_label]
      ret
    end
    

  end
end