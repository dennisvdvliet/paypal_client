# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Integration' do
  let(:params) do
    {
      client_id: client_id,
      client_secret: client_secret,
      sandbox: true,
      cache: ActiveSupport::Cache::MemoryStore.new,
      version: 'v1'
    }
  end

  let(:client_id) { ENV.fetch('PAYPAL_CLIENT_ID') }
  let(:client_secret) { ENV.fetch('PAYPAL_CLIENT_SECRET') }
  let(:client) { PaypalClient::Client.new(**params) }

  describe 'authentication' do
    context 'with valid credentials' do
      it 'fetches a token from Paypal' do
        expect { client.auth_token(force: true) }.not_to raise_error
      end
    end

    context 'with invalid credentials' do
      let(:client_id) { 'invalid' }

      it 'raises PaypalClient::Errors::AuthenticationFailure when fetching auth token' do
        expect { client.auth_token(force: true) }.to raise_error(PaypalClient::Errors::AuthenticationFailure)
      end
    end
  end

  describe 'error handling' do
    context 'when making GET request for non existing resource' do
      it 'raises PaypalClient::Errors::ResourceNotFound' do
        expect { client.get('/missing') }.to raise_error(PaypalClient::Errors::ResourceNotFound)
      end
    end
  end

  describe 'full flow' do

    @webhook = nil
    let(:data) do
      {
        url: 'https://bogus.com',
        event_types: [{ name: 'PAYMENT.AUTHORIZATION.CREATED' }]
      }
    end
    it 'creates, lists a deletes a webhook' do
      # Create webhook
      @webhook = client.post('/notifications/webhooks', data)
      
      # Check error message returned
      begin
        @webhook_duplicate = client.post('/notifications/webhooks', data)
      rescue PaypalClient::Errors::Error => error
        expect(error).to be_a(PaypalClient::Errors::InvalidRequest)
        expect(error.error).to eq('WEBHOOK_URL_ALREADY_EXISTS')
        expect(error.error_message).to eq('Webhook URL already exists')
      end

      # Ensure webhook is in response
      @webhooks = client.get('/notifications/webhooks')

      ids = @webhooks.body[:webhooks].collect { |webhook| webhook[:id] }
      expect(ids).to include(@webhook.body[:id])

      # Cleanup
      expect(client.delete("/notifications/webhooks/#{@webhook.body[:id]}").status).to eq(204)
    end
  end
end
