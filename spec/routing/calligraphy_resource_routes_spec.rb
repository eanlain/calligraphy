# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'calligraphy_resource', type: :routing do
  describe 'routes to WebDavRequests controller' do
    context 'for OPTIONS requests' do
      it do
        expect(options: '/test/one').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'one'
        )
      end
    end

    context 'for GET requests' do
      it do
        expect(options: '/test/two').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'two'
        )
      end
    end

    context 'for PUT requests' do
      it do
        expect(put: '/test/three').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'three'
        )
      end
    end

    context 'for DELETE requests' do
      it do
        expect(delete: '/test/four').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'four'
        )
      end
    end

    context 'for COPY requests' do
      it do
        expect(copy: '/test/five').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'five'
        )
      end
    end

    context 'for MOVE requests' do
      it do
        expect(move: '/test/six').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'six'
        )
      end
    end

    context 'for MKCOL requests' do
      it do
        expect(mkcol: '/test/seven').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'seven'
        )
      end
    end

    context 'for PROPFIND requests' do
      it do
        expect(propfind: '/test/eight').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'eight'
        )
      end
    end

    context 'for PROPPATCH requests' do
      it do
        expect(proppatch: '/test/nine').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'nine'
        )
      end
    end

    context 'for LOCK requests' do
      it do
        expect(lock: '/test/ten').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'ten'
        )
      end
    end

    context 'for UNLOCK requests' do
      it do
        expect(unlock: '/test/eleven').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'eleven'
        )
      end
    end

    context 'for HEAD requests' do
      it do
        expect(head: '/test/twelve').to route_to(
          controller: 'calligraphy/rails/web_dav_requests',
          action: 'invoke_method',
          resource: 'twelve'
        )
      end
    end
  end
end
