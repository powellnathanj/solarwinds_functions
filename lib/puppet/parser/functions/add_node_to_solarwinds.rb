require "uri"
require "yaml"
require "json"
require "net/http"

# This is a custom function to add nodes to Solarwinds that aren't already there.
module Puppet::Parser::Functions
  newfunction(:add_node_to_solarwinds) do |args|
    username  = function_hiera(['solarwinds_functions::config::username'])
    password  = function_hiera(['solarwinds_functions::config::password'])
    queryurl  = function_hiera(['solarwinds_functions::config::queryurl'])
    addurl    = function_hiera(['solarwinds_functions::config::addurl'])
    community = function_hiera(['solarwinds_functions::config::community'])
    nodename  = lookupvar('fqdn')
    ipaddr    = lookupvar('ipaddress')

    response = checkstatus(nodename, username, password, queryurl)

    if response == '{"results":[]}'
      addhost(nodename, ipaddr, username, password, addurl, community)
    end

  end
end

# Reach out to the Solarwinds (Orion) API and ask if the host is present
def checkstatus(nodename, username, password, queryurl)

  uri = URI.parse("#{queryurl}")
  query = {"query" => "SELECT NodeID FROM Orion.Nodes WHERE NodeName=@name", "parameters" => {"name" => "#{nodename}"}}

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  
  request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
  request.body = query.to_json
  request.basic_auth("#{username}", "#{password}")

  response = http.request(request)

  return response.body.to_s
end

# If the host was not present in the checkstatus() method, then we add it
def addhost(nodename, ipaddr, username, password, addurl, community)

  uri = URI.parse("#{addurl}")
  node = { "EntityType" => "Orion.Nodes", "IPAddress" => "#{ipaddr}",
    "Caption"=> "#{nodename}", "DynamicIP" => "False", "EngineID" => 1, 
    "Status" => 1, "UnManaged" => "False", "Allow64BitCounters" => "True", 
    "SysObjectID" => "", "MachineType" => "", "VendorIcon" => "", 
    "ObjectSubType" => "SNMP", "SNMPVersion" => 2, "Community" => "#{community}",
  }

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE

  request = Net::HTTP::Post.new(uri.request_uri, initheader = {'Content-Type' =>'application/json'})
  request.body = node.to_json
  request.basic_auth("#{username}", "#{password}")

  response = http.request(request)
end
