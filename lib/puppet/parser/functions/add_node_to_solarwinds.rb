require "uri"
require "yaml"
require "json"
require "net/http"

# This is a custom function to add nodes to Solarwinds that aren't already there.
module Puppet::Parser::Functions
  newfunction(:add_node_to_solarwinds) do |args|
    config = {}    

    config["username"]  = function_hiera(['solarwinds_functions::config::username'])
    config["password"]  = function_hiera(['solarwinds_functions::config::password'])
    config["queryurl"]  = function_hiera(['solarwinds_functions::config::queryurl'])
    config["addurl"]    = function_hiera(['solarwinds_functions::config::addurl'])
    config["community"] = function_hiera(['solarwinds_functions::config::community'])
    config["pollers"]   = function_hiera(['solarwinds_functions::config::pollers'])
    config["engineid"]  = config["pollers"].split(",").sample
    config["nodename"]  = lookupvar('fqdn')
    config["ipaddr"]    = lookupvar('ipaddress')

    File.open("/tmp/cf.log", 'a'){|fd| fd.puts config.inspect}
    
    response = checkstatus(config)

    if response == '{"results":[]}'
      addhost(config)
    end

  end
end

# Reach out to the Solarwinds (Orion) API and ask if the host is present
def checkstatus(config)

  uri = URI.parse("#{config["queryurl"]}")
  query = {"query" => "SELECT NodeID FROM Orion.Nodes WHERE NodeName=@name", "parameters" => {"name" => "#{config["nodename"]}"}}

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
  request.body = query.to_json
  request.basic_auth("#{config["username"]}", "#{config["password"]}")

  response = http.request(request)

  return response.body.to_s
end

# If the host was not present in the checkstatus() method, then we add it
def addhost(config)

  uri = URI.parse("#{config["addurl"]}")
  node = { "EntityType" => "Orion.Nodes", "IPAddress" => "#{config["ipaddr"]}",
    "Caption"=> "#{config["nodename"]}", "DynamicIP" => "False", "EngineID" => "#{config["engineid"]}", 
    "Status" => 1, "UnManaged" => "False", "Allow64BitCounters" => "True", 
    "SysObjectID" => "", "MachineType" => "", "VendorIcon" => "", 
    "ObjectSubType" => "SNMP", "SNMPVersion" => 2, "Community" => "#{config["community"]}",
  }

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
  request.body = node.to_json
  request.basic_auth("#{config["username"]}", "#{config["password"]}")

  response = http.request(request)
end
