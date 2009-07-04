# Include hook code here

%w[super_inplace_controls calendar_date_select includes_helper jrails_hacks.rb].each { |file| 
  require File.join( File.dirname(__FILE__), "lib", file) 
}

# Hook code


ActionController::Base.send :extend, Flvorful::SuperInplaceControls::ControllerMethods
ActionController::Base.send :include, Flvorful::SuperInplaceControls::InstanceMethods
ActionView::Base.send :include, Flvorful::SuperInplaceControls::HelperMethods
ActionView::Base.send :include, Flvorful::CustomHelpers
ActionView::Helpers::FormHelper.send :include, CalendarDateSelect::FormHelper
ActionView::Base.send :include, CalendarDateSelect::FormHelper
ActionView::Base.send :include, CalendarDateSelect::IncludesHelper
ActionView::Base.send :include, Flvorful::Helpers::JavaScriptGenerator::GeneratorMethods