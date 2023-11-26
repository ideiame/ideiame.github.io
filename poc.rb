require 'bundler/setup'
require 'bundler/inline'

gemfile(true) do
  gem 'ffast', path: '../fast'
  gem 'pry'
end

require 'fast'
require 'fast/sql'

ast = Fast.parse_sql_file('file.sql')

binding.pry

