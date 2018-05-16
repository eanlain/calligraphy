# frozen_string_literal: true

require 'rails_helper'
require 'support/request_helpers'
require 'support/examples/acl'

RSpec.describe 'acl', type: :request do
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
    describe 'acl' do
      before(:each) do
        Calligraphy::FileResource.create resource: 'top'
      end

      it 'grants the proper privileges' do
        acl '/webdav/top', headers: {
          RAW_POST_DATA: Support::Examples::Acl.rfc3744_8_1_2
        }
      end
    end
  end
end
