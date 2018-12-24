# PaypalClient

Ruby client for the [PayPal REST API](https://developer.paypal.com/docs/api/overview/). PayPal offers their own [SDK](https://github.com/paypal/PayPal-Ruby-SDK) but that felt a big heavy and was not seeing active development at the end of 2018.

PaypalClient is using Faraday to make the http calls to the Paypal API and uses ActiveSupport::Cache::MemoryStore to store the auth token required to make authenticated requests to Paypal [more info](https://developer.paypal.com/docs/api/overview/#authentication-and-authorization).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'paypal_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paypal_client

## Usage

To [list payments](https://developer.paypal.com/docs/api/payments/v1/#payment_list)

```ruby
paypal_client = PaypalClient::Client.build
response = paypal_client.get('/payments/payments').body
response[:payments].each do |payment|
  puts "Paypal payment with ID: #{payment[:id]}"
end
```

`PaypalClient::Client.build` requires the following environment variables to be set:

```shell
PAYPAL_CLIENT_ID=<paypal_client_id>
PAYPAL_CLIENT_SECRET=<paypal_client_secret>
PAYPAL_SANDBOX=true
```

You can also configure the client using `PaypalClient::Client.new` as in the following example.

```ruby
paypal_client = PaypalClient::Client.new(
  client_id: <paypal_client_id>,
  client_secret: <paypal_client_secret>,
  sandbox: true,
  cache: Rails.cache,
  version: 'v1'
)
```

## Documentation

TODO

## Testing

There is a good amount of unit testing in `spec/paypal_client_spec.rb`. To run those test **no** active Paypal Developer account is required. To run the tests in `spec/integration/integration_spec.rb` valid Paypal sandbox credentials are required.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/dennisvdvliet/paypal_client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Code of Conduct

Everyone interacting in the PaypalClient project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/dennisvdvliet/paypal_client/blob/master/CODE_OF_CONDUCT.md).
