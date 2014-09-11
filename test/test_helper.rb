lib = File.expand_path('../lib', File.dirname(__FILE__))
$LOAD_PATH.unshift(lib) if File.directory?(lib) && !$LOAD_PATH.include?(lib)

require 'check_passenger'
require 'minitest'
require 'minitest/autorun'
