module Flvorful
	module Helpers
		class JavaScriptGenerator
			module GeneratorMethods
				def remove_class_name(id, *klass)
					call "#{ActionView::Helpers::PrototypeHelper::JQUERY_VAR}(\"#{jquery_id(id)}\").removeClass", klass
				end
			end
		end
	end
end

