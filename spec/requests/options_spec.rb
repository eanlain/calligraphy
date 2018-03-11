# frozen_string_literal: true

require 'rails_helper'
require 'support/request_helpers'

RSpec.describe 'OPTIONS', type: :request do
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
    context 'when not using extended MKCOL support' do
      before(:each) do
        allow_any_instance_of(Calligraphy::FileResource).to receive(
          :enable_extended_mkcol?
        ).and_return(false)
      end

      it 'advertises support for all 3 WebDAV classes' do
        options '/webdav/special'

        %w[1 2 3].each { |c| expect(response.headers['DAV']).to include(c) }
      end

      it 'does not advertise support for extended-mkcol' do
        options '/webdav/special'

        expect(response.headers['DAV']).to_not include('extended-mkcol')
      end
    end

    context 'when using extended MKCOL support' do
      before(:each) do
        allow_any_instance_of(Calligraphy::FileResource).to receive(
          :enable_extended_mkcol?
        ).and_return(true)
      end

      it 'advertises support for all 3 WebDAV classes' do
        options '/webdav/special'

        %w[1 2 3].each { |c| expect(response.headers['DAV']).to include(c) }
      end

      it 'advertises support for extended-mkcol' do
        options '/webdav/special'

        expect(response.headers['DAV']).to include('extended-mkcol')
      end
    end
  end
end
