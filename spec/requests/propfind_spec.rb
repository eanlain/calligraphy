# frozen_string_literal: false

require 'rails_helper'
require 'support/request_helpers'
require 'support/examples/propfind'
require 'support/examples/proppatch'

RSpec.describe 'PROPFIND', type: :request do
  before(:context) do
    Calligraphy::FileResource.setup
  end

  before(:each) do
    skip_authentication
  end

  after(:context) do
    Calligraphy::FileResource.cleanup
  end

  context 'with xml defintiion' do
    before(:each) do
      Calligraphy::FileResource.create resource: 'bar.html'

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
