# A Ruby GraphQL Client

**Note: do not use this yet. It's experimental and changes frequently**

This is an early stage attempt at a *generic* GraphQL client in Ruby.

Below you'll find some usage examples.

## Usage

Create a client:

```ruby
schema_string = File.read('path/to/schema.json')
schema = GraphQLSchema.new(schema_string)

client = GraphQL::Client.new do
  configure do |c|
    c.url = 'http://example.com'
  end
end
```

### Raw Queries

```ruby
client.raw_query('
  query {
    shop {
       name
      }
    }
')
```

### Query Builder

```ruby
query = client.build_query do |q|
  q.add_field('shop') do |shop|
    shop.add_field('name')
  end
end

client.query(query)
```

More complex query using a connection:

```ruby
query = client.build_query do |q|
  q.add_field('product', id: 'gid://Product/1') do |product|
    product.add_connection('images', first: 10) do |connection|
      connection.add_field('src')
    end
  end

  q.add_field('shop') do |shop|
    shop.add_field('name')

    shop.add_field('billingAddress') do |billing_address|
      billing_address.add_fields('city', 'country')
    end
  end
end

client.query(query)
```

### ActiveRecord Style API

This API intends to mimic the style of ActiveRecord/ActiveResource for fetching
GraphQL resources.

You can fetch objects, lists and connections through any schema's graph in a
fairly straightforward way with fields explicitly specified:

```ruby
shop = @client.shop
address = shop.billing_address(:city)
assert_equal('Toronto', address.city)

products = shop.products(:title)
assert_equal 5, products.length
assert_equal 'Concrete Coat', products.first.title
```

An `includes` keyword allows you to nest relationships and efficiently fetch
all the data required in one query:

```ruby
publications = @client
  .shop
  .channel_by_handle(:name, handle: 'buy-button-dev')
  .product_publications(includes: { product: ['title'] })
```

You can also nest includes:

```ruby
collection_publications = @client
      .shop
      .channel_by_handle(handle: 'buy-button-dev')
      .collection_publications(
        first: 10,
        includes: { collection: ['id', 'title', image: ['id', 'src']] }
      )
```

Mutations are very much a work in progress, and currently match based on a
naming convention used by Shopify that matches models and their actions.
Updating, creating and deleting objects are supported:

```ruby
public_access_tokens = @client.shop.public_access_tokens(:title)

new_token = public_access_tokens.create(title: 'Test')
assert_equal 32, new_token.access_token.length
assert_equal 'Test', new_token.title

new_token.title = 'Test'
new_token.save

new_token.destroy
```

## Testing

Right now the tests are fairly tricky to get correct. Most of the functionality
is covered by integration tests which can use a production or local Shopify
store and operates in the following contexts:

- Merchant
- Channel (via the Merchant API)
- Customer (via the StoreFront API)

The following environment variables are used to drive the integration tests:

- `MERCHANT_USERNAME`
- `MERCHANT_PASSWORD`
- `MERCHANT_TOKEN`
- `STOREFRONT_TOKEN`

Unit tests will run regardless of which variables are present.

## TODO

There's a lot missing right now. Some of the more immediate things to fix are:

- Query validation
- Mutation matching and validation
- GraphQL-level response validation and error checks
