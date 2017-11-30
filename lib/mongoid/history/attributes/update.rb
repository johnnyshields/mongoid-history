module Mongoid
  module History
    module Attributes
      class Update < ::Mongoid::History::Attributes::Base
        def attributes
          @attributes = {}
          changes.each do |k, v|
            if trackable_class.tracked_embeds_one?(k)
              insert_embeds_one_changes(k, v)
            elsif trackable_class.tracked_embeds_many?(k)
              insert_embeds_many_changes(k, v)
            elsif trackable_class.tracked?(k, :update)
              @attributes[k] = v unless v.all?(&:blank?)
            end
          end
          @attributes
        end

        private

        def insert_embeds_one_changes(relation, value)
          relation = trackable_class.database_field_name(relation)
          permitted_attrs = trackable_class.tracked_embeds_one_attributes(relation)
          relation_class = trackable_class.embeds_one_class(relation)
          paranoia_field = Mongoid::History.trackable_class_settings(relation_class)[:paranoia_field]
          original_value = value[0][paranoia_field].present? ? {} : value[0].slice(*permitted_attrs)
          modified_value = value[1][paranoia_field].present? ? {} : value[1].slice(*permitted_attrs)
          return if original_value == modified_value
          @attributes[relation] = [original_value, modified_value]
        end

        def insert_embeds_many_changes(relation, value)
          relation = trackable_class.database_field_name(relation)
          permitted_attrs = trackable_class.tracked_embeds_many_attributes(relation)
          relation_class = trackable_class.embeds_many_class(relation)
          paranoia_field = Mongoid::History.trackable_class_settings(relation_class)[:paranoia_field]
          original_value = value[0].reject { |rel| rel[paranoia_field].present? }.map { |v_attrs| v_attrs.slice(*permitted_attrs) }
          modified_value = value[1].reject { |rel| rel[paranoia_field].present? }.map { |v_attrs| v_attrs.slice(*permitted_attrs) }
          return if original_value == modified_value
          @attributes[relation] = [original_value, modified_value]
        end
      end
    end
  end
end
