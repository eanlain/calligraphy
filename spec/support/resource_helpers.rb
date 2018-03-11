# frozen_string_literal: true

RESOURCES_TO_TEST_AGAINST = [
  Calligraphy::FileResource
].freeze

module RSpecMethods
  def setup; end

  def cleanup; end

  def create(resource:, content: 'Hi hi!'); end
end

module FileResourceHelpers
  def setup
    tmp_dir = Rails.root.join('../../tmp').to_path
    Dir.mkdir tmp_dir unless File.exist? tmp_dir

    FileUtils.rm_r resource_root if File.exist? resource_root
    Dir.mkdir resource_root
  end

  def cleanup
    FileUtils.rm_r resource_root if File.exist? resource_root
  end

  def create(resource:, content: 'Hello world')
    resource = Calligraphy::FileResource.new(
      resource: resource,
      root_dir: resource_root
    )
    resource.write content
  end

  def resource_root
    Rails.root.join('../../tmp/webdav').to_path
  end
end

RESOURCES_TO_TEST_AGAINST.each do |resource_class|
  resource_class.send :extend, RSpecMethods
end

module Calligraphy
  class FileResource
    extend FileResourceHelpers
  end
end
