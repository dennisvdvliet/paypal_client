# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe PaypalClient::Errors::Error do
  subject { described_class.new(error_message, http_status: http_status, http_body: http_body, code: code) }
  let(:code) { 'ERROR'}
  let(:error_message) { 'Something went wrong' }
  let(:http_body) { 'Body' }
  let(:http_status) { 400 }

  describe '#inspect' do
    it 'returns a string' do
      expect(subject.inspect).to be_a(String)
    end

    it 'ouputs a readable message' do
      expect(subject.inspect).to eq('#<PaypalClient::Errors::Error: ERROR: Something went wrong (400) status_code: 400 body: Body>')
    end

    it 'returns a useful message' do
      expect(subject.message).to eq('ERROR: Something went wrong (400)')
    end
  end
end
