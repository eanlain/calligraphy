Rails.application.routes.draw do
  calligraphy_resource :test
  calligraphy_resource :webdav, resource_class: Calligraphy::FileResource
end
