require 'uri'

module GraphQL
  module Client
    JSON_MIME_TYPE = 'application/json'.freeze
    DEFAULT_HEADERS = { 'Accept' => JSON_MIME_TYPE, 'Content-Type' => JSON_MIME_TYPE }

    NetworkError = Class.new(StandardError)

    class Request
      attr_reader :type

      def initialize(client:, type: nil)
        @client = client
        @type = type
      end

      def from_query(query)
        puts "Query: #{query}" if @client.debug
        response_body = send_request(query)
        Response.new(self, response_body)
      end

      def send_request(query)
        req = build_request(query)

        response = Net::HTTP.start(@client.url.hostname, @client.url.port, use_ssl: https?) do |http|
          http.request(req)
        end

        case response
        when Net::HTTPOK then
          puts "Response body: \n#{response.body}" if @client.debug
          response.body
        else
          raise NetworkError, "Response error - #{response.code}/#{response.message}"
        end
      end

      def find(id)
        type = if @type.name.end_with? 'Connection'
          @type.node_type
        else
          @type
        end

        field_name = type.name
        field_name[0] = field_name[0].downcase
        query = @client.build_query
        object_query = query.add_field(field_name, id: id)
        object_query.add_fields(*type.fields.select { |_, field| field.scalar? }.keys)
        puts "Query: #{query}" if @client.debug
        Response.new(self, send_request(query))
      end

      def simple_find(type_name)
        query = QueryBuilder.simple_find(@client.schema.type(type_name))
        puts "Query: #{query}" if @client.debug
        Response.new(self, send_request(query))
      end

      private

      def build_request(query)
        headers = DEFAULT_HEADERS.merge(@client.headers)

        Net::HTTP::Post.new(@client.url, headers).tap do |req|
          req.basic_auth(@client.username, @client.password)
          req.body = { query: query, variables: {} }.to_json
        end
      end

      def https?
        @client.url.scheme == 'https'
      end
    end
  end
end
