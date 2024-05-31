param acaenvInternalDefaultDomain string
param acaenvInternalStaticIp string
param vnet string

resource wxacatestprofilesvnet 'Microsoft.Network/virtualNetworks@2023-11-01' existing = {
  name: vnet
}

/// DNS for default name

// Private DNS Zones for internal ACA environment 
resource privateDNSdefaultDomain 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: acaenvInternalDefaultDomain
  location: 'global'
}

// link private dns to vnet
resource privateDNSlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: wxacatestprofilesvnet.name
  location: 'global'
  parent: privateDNSdefaultDomain
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: wxacatestprofilesvnet.id
    }
  }
}

// A record for internal container app in private DNS zone
resource aRecordDefaultDomain 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '*'
  parent: privateDNSdefaultDomain
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: acaenvInternalStaticIp
      }
    ]
  }
}


