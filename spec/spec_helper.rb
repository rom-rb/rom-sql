# encoding: utf-8

require "codeclimate-test-reporter"
CodeClimate::TestReporter.start

require 'rom-sql'

root = Pathname(__FILE__).dirname

Dir[root.join('shared/*.rb').to_s].each { |f| puts f; require f }

require root.join('support/db')
