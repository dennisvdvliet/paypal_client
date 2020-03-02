lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paypal_client/version'

Gem::Specification.new do |spec|
  spec.name          = 'paypal_client'
  spec.version       = PaypalClient::VERSION
  spec.authors       = ['Dennis van der Vliet']
  spec.email         = ['dennis@wetransfer.com']

  spec.summary       = 'API Client for the PayPal REST API'
  spec.description   = 'Faraday based API client for the PayPal REST API. Includes support for saving the authentication token and limited release endpoints.'
  spec.homepage      = 'https://github.com/dennisvdvliet/paypal_client'

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport', "#{(ENV['ACTIVESUPPORT_VERSION'] || '> 4.2.8')}"
  spec.add_dependency 'faraday', '~> 0.15'
  spec.add_dependency 'faraday_middleware', '~> 0.12'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rspec', '~> 3.0'

  spec.required_ruby_version = '>= 2.3'
end
