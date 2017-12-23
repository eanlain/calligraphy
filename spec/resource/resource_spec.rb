require 'rails_helper'

RSpec.describe 'Resource' do
  context 'base method' do
    resource_methods_without_inputs = %w(
      ancestor_exist? collection? create_collection delete_collection etag
      exists? lock_is_exclusive? lock_tokens locked? read readable? refresh_lock
      creationdate displayname getcontentlanguage getcontentlength getcontenttype
      getetag getlastmodified lockdiscovery resourcetype supportedlock
    )
    resource_methods_with_inputs = %w(
      can_copy? copy lock locked_to_user? propfind proppatch unlock write get_custom_property
    )

    resource_methods_without_inputs.each do |method|
      describe "##{method}" do
        it 'raises NotImplementedError' do
          resource = Calligraphy::Resource.new
          expect{resource.send(method)}.to raise_exception(NotImplementedError)
        end
      end
    end

    resource_methods_with_inputs.each do |method|
      describe "##{method}" do
        it 'raises NotImplementedError' do
          resource = Calligraphy::Resource.new
          expect{resource.send(method, nil)}.to raise_exception(NotImplementedError)
        end
      end
    end
  end
end
