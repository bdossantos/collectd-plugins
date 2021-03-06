#!/usr/bin/env ruby
#
# Pull MongoDB stats to Collectd
#
# Basics from https://github.com/sensu/sensu-community-plugins/blob/master/plugins/mongodb/mongodb-metrics.rb
#
# (c) 2014, Benjamin Dos Santos <benjamin.dossantos@gmail.com>
# https://github.com/bdossantos/collectd-plugins
#

require 'optparse'
require 'net/http'
require 'json'
require 'uri'

HOSTNAME = ENV['COLLECTD_HOSTNAME'] || `hostname -f`.chomp
INTERVAL = ENV['COLLECTD_INTERVAL'] || 10

options = Struct.new('Options', :host, :user, :password).new
options.host = '127.0.0.1'
options.user = ENV['COLLECTD_MONGODB_USER'] || 'monitoring'
options.password = ENV['COLLECTD_MONGODB_PASSWORD'] || nil

optparse = OptionParser.new do |opts|
  opts.banner = 'Usage: mongodb-exec.rb [-h host] [-p port]'

  opts.on('-h', '--host HOST', String, 'Host name or IP address') do |h|
    options.host = h
  end

  opts.on('-u', '--user USER', String, 'User') do |u|
    options.user = u
  end

  opts.on('-p', '--password PASSWORD', String, 'Password') do |p|
    options.password = p
  end

  opts.on('-?', '--help', 'Display this screen') do
    puts opts
    exit 0
  end
end

begin
  optparse.parse!
  raise OptionParser::MissingArgument.new('host is required') unless options.host
rescue OptionParser::InvalidOption, OptionParser::MissingArgument => e
  puts e.message
  puts optparse

  exit 3
end

begin
  STDOUT.sync = true

  while true do
    uri = URI.parse("http://#{options.host}:28017/_status")
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(options.user, options.password) if options.password

    response = http.request(request)
    raise 'Could not fetch MongoDB server status' if response.code.to_i != 200
    status = JSON.parse(response.body)['serverStatus']

    timestamp = Time.now.to_i

    status['opcounters'].each do |k, v|
      STDOUT.puts "PUTVAL #{HOSTNAME}/mongodb/counter-opcounters_#{k} interval=#{INTERVAL} #{timestamp}:#{v}"
    end

    status['globalLock']['currentQueue'].each do |k, v|
      STDOUT.puts "PUTVAL #{HOSTNAME}/mongodb/counter-globalLock_#{k} interval=#{INTERVAL} #{timestamp}:#{v}"
    end

    status['indexCounters'].each do |k, v|
      STDOUT.puts "PUTVAL #{HOSTNAME}/mongodb/counter-indexCounters_#{k} interval=#{INTERVAL} #{timestamp}:#{v}"
    end

    status['mem'].each do |k, v|
      next if k == 'supported'
      STDOUT.puts "PUTVAL #{HOSTNAME}/mongodb/bytes-mem_#{k} interval=#{INTERVAL} #{timestamp}:#{v}"
    end

    sleep INTERVAL
  end
end
