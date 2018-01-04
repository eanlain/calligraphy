# frozen_string_literal: true

require 'rails_helper'
require 'support/request_helpers'
require 'support/examples/ext_mkcol'

RSpec.describe 'mkcol', type: :request do
  before(:all) do
    tmp_dir = Rails.root.join('../../tmp').to_path
    Dir.mkdir tmp_dir unless File.exists? tmp_dir

    webdav_dir = Rails.root.join('../../tmp/webdav').to_path
    FileUtils.rm_r webdav_dir if File.exists? webdav_dir
    Dir.mkdir webdav_dir
  end

  before(:each) do
    allow(Calligraphy).to receive(:enable_digest_authentication)
      .and_return(false)
  end

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
