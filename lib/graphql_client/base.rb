module GraphQL
  module Client
    class Base
      attr_reader :schema, :url, :username, :password, :per_page, :headers, :debug

      def initialize(schema:, url:, username: '', password: '', per_page: 100, headers: {}, debug: false)
        @schema = schema
        @url = URI(url)
        @username = username
        @password = password
        @per_page = per_page
        @headers = headers
        @debug = debug

        define_field_accessors
      end

      def build_query
        Query.new(schema: @schema)
      end

      private

      def define_field_accessors
        query_root = @schema.query_root
        fields = query_root.fields.select { |_, field| field.scalar? || field.object? }
        fields.each do |name, field|
          define_singleton_method(name) do |**arguments|
            ObjectProxy.new(type: field.base_type, client: self, **arguments)
          end
        end
      end
    end
  end
end
