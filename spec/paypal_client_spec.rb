# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe PaypalClient::Client do
  let(:sandbox) { true }
  let(:stubs) { nil }
  let(:cache) { ActiveSupport::Cache::MemoryStore.new }

  let(:params) do
    {
      client_id: 'client_id',
      client_secret: 'client_secret',
      cache: cache,
      sandbox: sandbox,
      version: 'v1'
    }
  end
  let(:client) { described_class.new(**params) }

  before do
    allow(client).to receive(:adapter).and_return([:test, stubs])
    cache.clear
  end

  describe '.build' do
    it 'returns an instance of Nu::Util::Paypal::Client' do
      expect(PaypalClient::Client.build).to be_a(PaypalClient::Client)
    end
  end

  describe '#connection' do
    it 'returns a faraday connection' do
      expect(client.connection).to be_a(Faraday::Connection)
    end

    it 'sets base_url to https://api.sandbox.paypal.com' do
      expect(client.connection.url_prefix.to_s).to eq('https://api.sandbox.paypal.com/')
    end

    it 'sets Accept header to application/json' do
      expect(client.connection.headers['Accept']).to eq('application/json')
    end

    it 'sets Content-Type header to application/json' do
      expect(client.connection.headers['Content-Type']).to eq('application/json')
    end

    context 'when in production mode' do
      let(:sandbox) { false }

      it 'sets base_url to https://api.paypal.com' do
        expect(client.connection.url_prefix.to_s).to eq('https://api.paypal.com/')
      end
    end
  end

  describe '#auth_token' do
    let(:response) do
      {
        access_token: 'token',
        expires_in: 12_340
      }
    end

    let(:headers) { {} }
    let(:body) { 'grant_type=client_credentials' }
    let(:stubs) do
      Faraday::Adapter::Test::Stubs.new do |stub|
        stub.post('/v1/oauth2/token', body, headers) { |_env| [200, {}, response.to_json] }
      end
    end

    it 'makes a POST call to /v1/oauth2/token' do
      client.auth_token
      expect { stubs.verify_stubbed_calls }.not_to raise_error
    end

    describe 'request headers' do
      describe 'Content-Type' do
        let(:headers) { { 'Content-Type' => 'application/x-www-form-urlencoded' } }

        it "is 'application/x-www-form-urlencoded" do
          client.auth_token
          expect { stubs.verify_stubbed_calls }.not_to raise_error
        end
      end

      describe 'Authentication' do
        let(:headers) { { 'Authorization' => 'Basic Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ=' } }

        it "is 'Basic Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ='" do
          client.auth_token
          expect { stubs.verify_stubbed_calls }.not_to raise_error
        end
      end
    end

    context 'when valid credentials given' do
      it 'saves the token in the cache' do
        expect(cache).to receive(:fetch)
        client.auth_token
      end

      it 'sets the expiry for the token' do
        expect(cache).to receive(:fetch).with(kind_of(String), expires_in: 12_340 - 3600)
        client.auth_token
      end

      # We are using #fetch but matching blocks is messy. But #fetch uses
      # #write in the end
      it 'writes the value for the token' do
        expect(cache).to receive(:write).with(kind_of(String), 'token', anything)
        client.auth_token
      end

      it 'calls POST /v1/oauth2/token once' do
        expect(client.connection).to receive(:post).once.and_call_original
        client.auth_token

        client.auth_token
      end
    end

    context 'when invalid credentials supplied' do
      let(:stubs) do
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post('/v1/oauth2/token', body, headers) { |_env| [401, {}, {}.to_json] }
        end
      end

      it 'does NOT save token in cache and raises error' do
        expect(cache).to_not receive(:fetch)

        expect { client.auth_token }.to raise_error PaypalClient::ResponseError
      end
    end

    context 'when token refresh forced' do
      it 'calls POST /v1/oauth2/token once' do
        expect(client.connection).to receive(:post).twice.and_call_original
        client.auth_token

        client.auth_token(force: true)
      end
    end
  end

  describe 'making requests' do
    context 'with invalid token' do
      before do
        allow(client).to receive(:auth_token).and_return('invalid-token')
      end

      describe '#get' do
        let(:stubs) do
          Faraday::Adapter::Test::Stubs.new do |stub|
            stub.get('/v1/payments/payment') { |_env| [401, {}, { ok: false }.to_json] }
          end
        end

        it 'raises a Nu::Util::Paypal::ResponseError' do
          expect { client.get('/payments/payment') }.to raise_error PaypalClient::ResponseError
        end
      end
    end

    context 'with valid token' do
      before do
        allow(client).to receive(:auth_token).and_return('token')
      end

      describe '#get' do
        let(:stubs) do
          Faraday::Adapter::Test::Stubs.new do |stub|
            stub.get('/v1/payments/payment') { |_env| [200, {}, { ok: true }.to_json] }
          end
        end

        it 'makes a GET request to /v1/payments/payment' do
          client.get('/payments/payment')
          expect { stubs.verify_stubbed_calls }.not_to raise_error
        end

        it 'returns a Faraday::Response object' do
          expect(client.get('/payments/payment')).to be_a(Faraday::Response)
        end
      end

      describe '#post' do
        let(:stubs) do
          Faraday::Adapter::Test::Stubs.new do |stub|
            stub.post('/v1/payments/payment', { ok: true }.to_json) { |_env| [200, {}, { ok: true }.to_json] }
          end
        end

        it 'makes a POST request to /v1/payments/payment' do
          client.post('/payments/payment', ok: true)
          expect { stubs.verify_stubbed_calls }.not_to raise_error
        end

        it 'returns a Faraday::Response object' do
          expect(client.post('/payments/payment', ok: true)).to be_a(Faraday::Response)
        end
      end

      describe '#patch' do
        let(:stubs) do
          Faraday::Adapter::Test::Stubs.new do |stub|
            stub.patch('/v1/payments/payment', { ok: true }.to_json) { |_env| [200, {}, { ok: true }.to_json] }
          end
        end

        it 'makes a PATCH request to /v1/payments/payment' do
          client.patch('/payments/payment', ok: true)
          expect { stubs.verify_stubbed_calls }.not_to raise_error
        end

        it 'returns a Faraday::Response object' do
          expect(client.patch('/payments/payment', ok: true)).to be_a(Faraday::Response)
        end
      end

      describe '#put' do
        let(:stubs) do
          Faraday::Adapter::Test::Stubs.new do |stub|
            stub.put('/v1/payments/payment', { ok: true }.to_json) { |_env| [200, {}, { ok: true }.to_json] }
          end
        end

        it 'makes a PUT request to /v1/payments/payment' do
          client.put('/payments/payment', ok: true)
          expect { stubs.verify_stubbed_calls }.not_to raise_error
        end

        it 'returns a Faraday::Response object' do
          expect(client.put('/payments/payment', ok: true)).to be_a(Faraday::Response)
        end
      end
    end
  end
end
