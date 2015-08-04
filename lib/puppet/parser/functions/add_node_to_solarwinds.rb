require "uri"
require "yaml"
require "json"
require "net/http"

# This is a custom function to add nodes to Solarwinds that aren't already there.
module Puppet::Parser::Functions
  newfunction(:add_node_to_solarwinds) do |args|
    config   = YAML.load(function_file(["solarwinds_functions/sw.yml"]))
    nodename = lookupvar('fqdn')
    ipaddr   = lookupvar('ipaddress')
    username = config['config']['username']
    password = config['config']['password']

    response = checkstatus(nodename, config)

    unless response == {"results" => []}.to_json.to_s
      addhost(nodename, ipaddr, config)
    end

  end
end

# Reach out to the Solarwinds (Orion) API and ask if the host is present
def checkstatus(nodename, config)

  uri = URI.parse(config['config']['queryurl'])
  query = {"query" => "SELECT NodeID FROM Orion.Nodes WHERE DNS=@name", "parameters" => {"name" => "#{nodename}"}}

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
  request.body = query.to_json
  request.basic_auth(config['config']['username'], config['config']['password'])

  response = http.request(request)

  return response.to_s
end

# If the host was not present in the checkstatus() method, then we add it
def addhost(nodename, ipaddr, config)

  uri = URI.parse(config['config']['addurl'])
  node = { "EntityType" => "Orion.Nodes", "IPAddress" => "#{ipaddr}",
    "Caption"=> "#{nodename}", "DynamicIP" => "False", "EngineID" => 1, 
    "Status" => 1, "UnManaged" => "False", "Allow64BitCounters" => "True", 
    "SysObjectID" => "", "MachineType" => "", "VendorIcon" => "", 
    "ObjectSubType" => "SNMP", "SNMPVersion" => 2, "Community" => config['config']['community'],
  }

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
  request.body = node.to_json
  request.basic_auth(config['config']['username'], config['config']['password'])

  response = http.request(request)
end
