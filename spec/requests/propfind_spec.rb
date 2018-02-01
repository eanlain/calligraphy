# frozen_string_literal: false

require 'rails_helper'
require 'support/request_helpers'
require 'support/examples/propfind'
require 'support/examples/proppatch'

RSpec.describe 'PROPFIND', type: :request do
  before(:all) do
    tmp_dir = Rails.root.join('../../tmp').to_path
    Dir.mkdir tmp_dir unless File.exist? tmp_dir

    webdav_dir = Rails.root.join('../../tmp/webdav').to_path
    FileUtils.rm_r webdav_dir if File.exist? webdav_dir
    Dir.mkdir webdav_dir
  end

  before(:each) do
    allow(Calligraphy).to receive(:enable_digest_authentication)
      .and_return(false)
  end

  context 'with xml defintiion' do
    before(:each) do
      put '/webdav/bar.html', headers: {
        RAW_POST_DATA: 'hello world'
      }
      proppatch '/webdav/bar.html', headers: {
        RAW_POST_DATA: Support::Examples::Proppatch.rfc4918_9_2_2
      }
    end

    describe 'allprop' do
      it 'returns all live and dead properties' do
        propfind '/webdav/bar.html', headers: {
          RAW_POST_DATA: Support::Examples::Propfind.allprop
        }

        property_methods = Calligraphy::FileResource::DAV_PROPERTY_METHODS -
                           %w[allprop propname]

        expect(response.status).to eq(207)
        expect(response.body).to include('Authors')
        expect(response.body).to include('Author>')
        expect(response.body).to include('Jim')
        expect(response.body).to include('Roy')

        property_methods.each do |property_method|
          expect(response.body).to include(property_method)
        end
      end
    end

    describe 'propname' do
      it 'returns all property names' do
        propfind '/webdav/bar.html', headers: {
          RAW_POST_DATA: Support::Examples::Propfind.propname
        }

        expect(response.status).to eq(207)
        expect(response.body).to include('Authors/')
        expect(response.body).to_not include('Author/')
      end
    end
  end
end
