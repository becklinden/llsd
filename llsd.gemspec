lib = File.expand_path('../lib', __FILE__)
$:.unshift lib unless $:.include? lib

require 'llsd/version'

Gem::Specification.new do |s|
  s.name      = 'llsd'
  s.version   = LLSD::VERSION
  s.date      = Time.now.strftime('%Y-%m-%d')
  s.summary   = 'An implementation of LLSD (Linden lab Structured Data) in Ruby'
  s.homepage  = 'https://github.com/becklinden/llsd'
  s.email     = 'beck@lindenlab.com'
  s.authors   = ['Beck Linden', 'Joshua Linden']

  s.files     = %w(LICENSE Rakefile)
  s.files    += Dir['lib/**/*']
  s.files    += Dir['test/**/*']
end
