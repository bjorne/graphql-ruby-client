module GraphQL
  module Client
    class Type
      attr_reader :connections, :field_arguments, :fields, :lists, :methods, :objects, :name

      def initialize(name, type)
        @connections = {}
        @field_arguments = {}
        @fields = {}
        @lists = {}
        @methods = {}
        @name = name
        @objects = {}
        @type = type

        unless @type['fields'].nil?
          @type['fields'].each do |field|
            if field.key?('args')
              unless field['args'].empty?
                @field_arguments[field['name']] = []
                field['args'].each do |argument|
                  @field_arguments[field['name']] << GraphQL::Client::Argument.new(argument['name'], argument['description'])
                end

                unless field.fetch('type', {}).fetch('ofType', nil).nil?
                  if field.fetch('type', {}).fetch('ofType', {}).fetch('name', '').end_with? 'Connection'
                    @connections[field['name']] = determine_type(field['type'])
                    next
                  else
                    type = determine_type(field['type'])
                    @lists[field['name']] = type
                    next
                  end
                end
              end
            end

            type_name = determine_type(field['type'])
            kind = determine_kind(field)
            new_field = Field.new(field['name'], type_name, false)

            case kind
            when 'LIST'
              @lists[field['name']] = new_field
            when 'OBJECT'
              @objects[field['name']] = new_field
            else
              if !field.fetch('args', []).empty?
                @methods[field['name']] = new_field
              else
                @fields[field['name']] = new_field
              end
            end
          end
        end
      end

      def camel_case(string)
        string = string.replace(string.split("_").each_with_index { |s, i| s.capitalize! unless i == 0 }.join(""))
        string[0] = string[0].downcase
        string
      end

      def camel_case_name
        camel_case(@name)
      end

      private

      def determine_kind(field)
        if field['type']['ofType']
          field['type']['ofType']['kind']
        else
          field['type']['kind']
        end
      end

      def determine_type(type)
        return type if type.is_a? String

        if type.key?('ofType')
          return determine_type(type['ofType']) unless type['ofType'].nil?
        end

        type['name']
      end
    end
  end
end
