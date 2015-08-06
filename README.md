Solarwinds/Puppet Custom Function
=================================

This is a Puppet custom function for adding nodes to Solarwinds automagically

Every puppet run the function will reach out to your Solarwinds instance and ask if it is already being monitored.  If it finds out that it does not exist it will add itself.

Installation
===========

Add this repository to the modules directory of your puppet environment.

Then add the following to your hieradata (common.yaml or other)

A username/password that has authorization to update Solarwinds via the Orion API
    
    solarwinds_functions::config::username: ""
    solarwinds_functions::config::password: ""

The url you'd like to use for querying (ex: https://sw.yourdomain.com:17778/SolarWinds/InformationService/v3/Json/Query)
    
    solarwinds_functions::config::queryurl: ""

The url you'd like to use for Creating (ex: https://sw.yourdomain.com:17778/SolarWinds/InformationService/v3/Json/Create/Orion.Nodes)
    
    solarwinds_functions::config::addurl: ""

The SNMP Communit String you want to use
    
    solarwinds_functions::config::community: ""

Add the IDs of your pollers so it can pick one at random to spread the load. This should be a comma separated single string (ex: "2,3,4,5")
    
    solarwinds_functions::config::pollers: ""

Finally, in a profile manifest add the following function:
    
    add_node_to_solarwinds()
