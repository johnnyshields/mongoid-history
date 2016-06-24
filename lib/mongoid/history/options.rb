module Mongoid
  module History
    class Options
      attr_reader :trackable, :options

      def initialize(trackable)
        @trackable = trackable
      end

      def scope
        trackable.collection_name.to_s.singularize.to_sym
      end

      def default_options
        { on: :all,
          except: [:created_at, :updated_at],
          tracker_class_name: nil,
          modifier_field: :modifier,
          version_field: :version,
          changes_method: :changes,
          scope: scope,
          track_create: false,
          track_update: true,
          track_destroy: false }
      end

      def parse(options = {})
        @options = default_options.merge(options)
        prepare_skipped_fields
        prepare_tracked_fields_and_relations
        remove_reserved_fields
        @options
      end

      private

      def prepare_skipped_fields
        # normalize :except fields to an array of database field strings
        @options[:except] = Array(options[:except])
        @options[:except] = options[:except].map { |field| trackable.database_field_name(field) }.compact.uniq
      end

      def prepare_tracked_fields_and_relations
        @options[:on] = Array(options[:on])

        # :all is just an alias to :fields for now, to support existing users of `mongoid-history`
        # In future, :all will track all the fields and associations of trackable class
        @options[:on] = options[:on].map { |opt| (opt == :all) ? :fields : opt }
        @options[:on] = options[:on].map { |opt| trackable.database_field_name(opt) }.compact.uniq

        if options[:on].include?('fields')
          @options[:tracked_fields] = trackable.fields.keys
          @options[:tracked_relations] = options[:on].reject { |opt| opt == 'fields' }
        else
          @options[:tracked_fields] = trackable.fields.keys & options[:on]
          @options[:tracked_relations] = options[:on] - options[:tracked_fields]
        end

        @options[:tracked_fields] = options[:tracked_fields] - options[:except]
        @options[:tracked_relations] = options[:tracked_relations] - options[:except]
      end

      def remove_reserved_fields
        @options[:tracked_fields] = options[:tracked_fields] - reserved_fields
        @options[:tracked_relations] = options[:tracked_relations] - reserved_fields
        @options[:tracked_dynamic] = options[:tracked_relations].dup
      end

      def reserved_fields
        ['_id', '_type', options[:version_field].to_s, "#{options[:modifier_field]}_id"]
      end
    end
  end
end
