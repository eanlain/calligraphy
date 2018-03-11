# frozen_string_literal: true

require 'rails_helper'
require 'support/request_helpers'
require 'support/examples/ext_mkcol'

RSpec.describe 'mkcol', type: :request do
  before(:context) do
    Calligraphy::FileResource.setup
  end

  before(:each) do
    skip_authentication
  end

  after(:context) do
    Calligraphy::FileResource.cleanup
  end

  context "for #{Calligraphy::FileResource}" do
    it 'creates a collection with additional properties' do
      allow_any_instance_of(Calligraphy::FileResource).to receive(
        :valid_resourcetypes
      ).and_return(%w[collection special-resource])

      expect(Dir).to receive(:mkdir).and_call_original
      expect_any_instance_of(Calligraphy::FileResource).to receive(
        :proppatch
      )

      mkcol '/webdav/special', headers: {
        RAW_POST_DATA: Support::Examples::ExtMkcol.rfc5689_3_4
      }

      expect(response.body.empty?).to eq(true)
      expect(response.status).to eq(201)
    end

    context 'with an invalid resource type' do
      it 'returns an error response' do
        mkcol '/webdav/special', headers: {
          RAW_POST_DATA: Support::Examples::ExtMkcol.rfc5689_3_4
        }

        expect(response.status).to eq(403)
        expect(response.body).to include('mkcol-response')
        expect(response.body).to include('valid-resourcetype')
      end
    end
  end
end
