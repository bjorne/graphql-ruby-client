module GraphQL
  module Client
    class ConnectionQuery
      def initialize(parent:, parent_field:, field:, return_type:, client:)
        @parent_field = parent_field
        @root_type = parent.type
        @root_type_name = parent.type.name
        @root_id = parent.id
        @parent = parent
        @field = field
        @return_type = return_type
        @client = client
        @schema = client.schema
        @per_page = client.per_page
      end

      def query(after: nil)
        query_builder.connection_from_object(
          @root_type,
          @root_id,
          @field,
          parent_field: @parent_field,
          per_page: @per_page,
          after: after
        )
      end

      def query_builder
        QueryBuilder.new(@schema)
      end
    end
  end
end
