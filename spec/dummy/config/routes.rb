Rails.application.routes.draw do
  calligraphy_resource :test
  calligraphy_resource :webdav,
    resource_class: Calligraphy::FileResource,
    resource_root_path: File.expand_path('../../../../tmp/webdav', __FILE__)
end
