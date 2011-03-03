module StateMachine
  module Integrations #:nodoc:
    module ActiveRecord
      version '2.x' do
        def self.active?
          ::ActiveRecord::VERSION::MAJOR == 2
        end
        
        def load_locale
          super if defined?(I18n)
        end
        
        def define_scope(name, scope)
          if owner_class.respond_to?(:named_scope)
            name = name.to_sym
            machine_name = self.name
            
            # Since ActiveRecord does not allow direct access to the model
            # being used within the evaluation of a dynamic named scope, the
            # scope must be generated manually.  It's necessary to have access
            # to the model so that the state names can be translated to their
            # associated values and so that inheritance is respected properly.
            owner_class.named_scope(name)
            owner_class.scopes[name] = lambda do |model, *states|
              machine_states = model.state_machine(machine_name).states
              values = states.flatten.map {|state| machine_states.fetch(state).value}
              
              ::ActiveRecord::NamedScope::Scope.new(model, scope.call(values))
            end
          end
          
          # Prevent the Machine class from wrapping the scope
          false
        end
        
        def invalidate(object, attribute, message, values = [])
          if defined?(I18n)
            super
          else
            object.errors.add(self.attribute(attribute), generate_message(message, values))
          end
        end
        
        def translate(klass, key, value)
          if defined?(I18n)
            super
          else
            value ? value.to_s.humanize.downcase : 'nil'
          end
        end
        
        def filter_attributes(object, attributes)
          object.send(:remove_attributes_protected_from_mass_assignment, attributes)
        end
      end
      
      version '2.0 - 2.2.x' do
        def self.active?
          ::ActiveRecord::VERSION::MAJOR == 2 && ::ActiveRecord::VERSION::MINOR < 3
        end
        
        def default_error_message_options(object, attribute, message)
          {:default => @messages[message]}
        end
      end
      
      version '2.0 - 2.3.1' do
        def self.active?
          ::ActiveRecord::VERSION::MAJOR == 2 && (::ActiveRecord::VERSION::MINOR < 3 || ::ActiveRecord::VERSION::TINY < 2)
        end
        
        def ancestors_for(klass)
          klass.self_and_descendents_from_active_record
        end
      end
      
      version '2.0 - 2.3.4' do
        def self.active?
          ::ActiveRecord::VERSION::MAJOR == 2 && (::ActiveRecord::VERSION::MINOR < 3 || ::ActiveRecord::VERSION::TINY < 5)
        end
        
        def load_i18n_version
        end
      end
      
      version '2.0.x' do
        def self.active?
          ::ActiveRecord::VERSION::MAJOR == 2 && ::ActiveRecord::VERSION::MINOR == 0
        end
        
        def supports_dirty_tracking?(object)
          false
        end
      end
      
      version '2.1.x - 2.3.x' do
        def self.active?
          ::ActiveRecord::VERSION::MAJOR == 2 && ::ActiveRecord::VERSION::MINOR > 0
        end
        
        def supports_dirty_tracking?(object)
          object.respond_to?("#{attribute}_changed?")
        end
      end
      
      version '2.3.2 - 2.3.x' do
        def self.active?
          ::ActiveRecord::VERSION::MAJOR == 2 && ::ActiveRecord::VERSION::MINOR == 3 && ::ActiveRecord::VERSION::TINY >= 2
        end
        
        def ancestors_for(klass)
          klass.self_and_descendants_from_active_record
        end
      end
    end
  end
end
