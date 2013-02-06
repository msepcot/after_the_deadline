# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "after_the_deadline"
  gem.version       = "0.1.0"
  gem.authors       = ["Michael J. Sepcot"]
  gem.email         = ["michael.sepcot@gmail.com"]
  gem.summary       = %q{A ruby library for playing with After The Deadline service}

  gem.files         = `git ls-files`.split($/)
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency 'crack', '~> 0.3.2'
end
