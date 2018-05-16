# frozen_string_literal: true

require 'rails_helper'
require 'support/request_helpers'

RSpec.describe 'Resource' do
  context 'base method' do
    resource_methods_without_inputs = %w[
      ancestor_exist? collection? create_collection delete_collection etag
      exists? lock_is_exclusive? locked? read readable? refresh_lock
      creationdate displayname getcontentlanguage getcontentlength
      getcontenttype getetag getlastmodified lockdiscovery resourcetype
      supportedlock
    ]
    resource_methods_with_inputs = %w[
      copy copy_options lock locked_to_user? propfind proppatch unlock write
    ]

    resource_methods_without_inputs.each do |method|
      describe "##{method}" do
        it 'raises NotImplementedError' do
          resource = Calligraphy::Resource.new

          expect { resource.send(method) }.to raise_exception(
            NotImplementedError
          )
        end
      end
    end

    resource_methods_with_inputs.each do |method|
      describe "##{method}" do
        it 'raises NotImplementedError' do
          resource = Calligraphy::Resource.new

          expect { resource.send(method, nil) }.to raise_exception(
            NotImplementedError
          )
        end
      end
    end

    describe '#dav_compliance' do
      it 'advertises full WebDAV compliance' do
        resource = Calligraphy::Resource.new
        expect(resource.dav_compliance).to eq('1, 2, 3')
      end
    end

    describe '#enable_access_control?' do
      it 'is not enabled by default' do
        resource = Calligraphy::Resource.new
        expect(resource.enable_access_control?).to eq(false)
      end
    end

    describe '#enable_extended_mkcol?' do
      it 'is not enabled by default' do
        resource = Calligraphy::Resource.new
        expect(resource.enable_extended_mkcol?).to eq(false)
      end
    end

    describe '#valid_resourcetypes' do
      it 'returns only a collection resourcetype by default' do
        resource = Calligraphy::Resource.new
        expect(resource.valid_resourcetypes).to match_array(['collection'])
      end
    end
  end
end
