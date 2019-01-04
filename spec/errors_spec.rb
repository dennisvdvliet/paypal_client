# frozen_string_literal: true

require_relative 'spec_helper'

RSpec.describe PaypalClient::Errors::Error do
  subject { described_class.new(message, http_status: http_status, http_body: http_body, code: code) }
  let(:code) {}
  let(:message) { 'Something went wrong' }
  let(:http_body) { 'Body' }
  let(:http_status) { 400 }

  describe '#inspect' do
    it 'returns a string' do
      expect(subject.inspect).to be_a(String)
    end

    it 'ouputs a readable message' do
      expect(subject.inspect).to eq('#<PaypalClient::Errors::Error: Something went wrong status_code: 400 body: Body>')
    end
  end
end
