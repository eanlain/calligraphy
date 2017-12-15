# Calligraphy

Calligraphy is a Web Distributed Authoring and Versioning (WebDAV) solution for Rails that:

* Provides a framework for handling WebDAV requests (e.g. `PROPFIND`, `PROPPATCH`)
* Allows you to extend WedDAV functionality to any type of resource
* Passes all of the [Litmus](https://github.com/eanlain/litmus) tests (using `Calligraphy::FileResource` and digest authentication)

## Getting Started

Add the following line to your Gemfile:

```ruby
gem 'calligraphy', :git => 'https://github.com/eanlain/calligraphy'
```

Then run `bundle install`

Next, set up a `calligraphy_resource` route in `config/routes.rb` with a `resource_class`.

```ruby
calligraphy_resource :webdav, resource_class: Calligraphy::FileResource
```

The above will create a route, `/webdav` that will be able to handle the following HTTP request methods:

* `OPTIONS`
* `GET`
* `PUT`
* `DELETE`
* `COPY`
* `MOVE`
* `MKCOL`
* `PROPFIND`
* `PROPPATCH`
* `LOCK`
* `UNLOCK`

The routes will also use the `Calligraphy::FileResource`, enabling Rails to carry out WebDAV actions on files.

## Extensibility

The `Calligraphy::Resource` class exposes all the methods used in the various `Calligraphy::WebDavRequest` classes.
To create a custom resource, simply inherit from `Calligraphy::Resource` and redefine the public methods you'd like to customize.

For example, to create a `CalendarResource`:

```ruby
module Calligraphy
  class CalendarResource < Resource

    def propfind(nodes)
      # custom implementation of propfind for CalendarResource
    end

    ...
  end
end
```

## License

Calligraphy is Copyright © 2017 Brandon Robins.
It is free software, and may be redistributed under the terms specified in the [LICENSE](/LICENSE) file.
