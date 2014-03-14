# CatarsePagosonline

Pagosonline integration with [Catarse](http://github.com/catarse/catarse) crowdfunding platform

## Installation

Add this lines to your Catarse application's Gemfile:

    gem 'pagosonline', git: 'git://github.com/carloshlopez/pagosonline.git'
    gem 'catarse_pagosonline', git: 'git://github.com/carloshlopez/pagosonline.git'

And then execute:

    $ bundle

## Usage

Configure the routes for your Catarse application. Add the following lines in the routes file (config/routes.rb):

    mount CatarsePagosonline::Engine => "/", :as => "catarse_pagosonline"

### Configurations

Create this configurations into Catarse database:

    pagosonline_test,  pagosonline_key and pagosonline_account_id

    pagosonline_test if "1" will be on test mode
    pagosonline_key you will find it in your pagosonline admin module
    pagosonline_account_id you'll get it from customer support

In Rails console, run this:

    Configuration.create!(name: "pagosonline_test", value: "1") 
    Configuration.create!(name: "pagosonline_key", value: "sdf4fs34442")
    Configuration.create!(name: "pagosonline_account_id", value: "2222")

  Currencies:
    "COP" -> default
    "ars"
    "mxn"
    "clp"
    "brl"
    "usd"

## Development environment setup

Clone the repository:

    $ git clone git://github.com/carloshlopez/catarse_pagosonline.git

Add the catarse code into test/dummy:

    $ git submodule add git://github.com/carloshlopez/catarse.git test/dummy

Copy the Catarse's gems to Gemfile:

    $ cat test/dummy/Gemfile >> Gemfile

And then execute:

    $ bundle

Replace the content of test/dummy/config/boot.rb by this:

    require 'rubygems'
    gemfile = File.expand_path('../../../../Gemfile', __FILE__)
    if File.exist?(gemfile)
      ENV['BUNDLE_GEMFILE'] = gemfile
      require 'bundler'
      Bundler.setup
    end
    YAML::ENGINE.yamler= 'syck' if defined?(YAML::ENGINE)

    $:.unshift File.expand_path('../../../../lib', __FILE__)


## Troubleshooting in development environment

Remove the admin folder from test/dummy application to prevent a weird active admin bug:

    $ rm -rf test/dummy/app/admin

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request


This project rocks and uses MIT-LICENSE.
