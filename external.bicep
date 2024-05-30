var rg = resourceGroup().name

var vnet ='${rg}-vnet'
var vnetCidr = '10.1.0.0/16'

var subnet = 'aca-external'
var subnetcidr = '10.1.1.0/24'

var caname1 = 'webtest-ext1'
var caname2 = 'webtest-ext2'

var caname1Internal = 'webtest-int1'

var subnetInternal = 'aca-internal'
var subnetInternalCidr = '10.1.2.0/24'

var acaenv = '${rg}-acaenv'
var avaenvInternal = '${rg}-acaenv-internal'

var workloadProfileName = 'x4Core16Mem'
var workloadProfileType = 'D4'

var laws = '${rg}-la'

var custom_domain_name='acatest.internal.com'
var custom_domain_certificate_password = 'P@ssword1234'
var custom_domain_cert = loadFileAsBase64('acatest.internal.com.pem')

var location = resourceGroup().location

// Virtual network
resource wxacatestprofilesvnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnet
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetCidr
      ]
    }
  }
}

// Subnet for external AVA environment
resource wxacatestprofilesvnet_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: subnet
  parent: wxacatestprofilesvnet
  properties: {
    addressPrefix: subnetcidr
    delegations: [
      {
        name: '0'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
  }
}

// subnet for internal ACA environment
resource wxacatestprofilesvnet_internal_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-11-01' = {
  name: subnetInternal
  parent: wxacatestprofilesvnet
  properties: {
    addressPrefix: subnetInternalCidr
    delegations: [
      {
        name: '0'
        properties: {
          serviceName: 'Microsoft.App/environments'
        }
      }
    ]
  }
}

// Log Analytics workspace
resource wxacatestprofilesla 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  location: location
  name: laws
}

// External ACA environment
resource wxacatestprofilesacaenv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: acaenv
  location: location
  properties: {
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: wxacatestprofilesvnet_subnet.id
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wxacatestprofilesla.properties.customerId
        sharedKey: wxacatestprofilesla.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
      {
        workloadProfileType: workloadProfileType
        name: workloadProfileName
        minimumCount: 1
        maximumCount: 2
      }
    ]
  }
}

// Internal ACA environment
resource wxacatestprofilesacaenv_internal 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: avaenvInternal
  location: location
  properties: {
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: wxacatestprofilesvnet_internal_subnet.id
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wxacatestprofilesla.properties.customerId
        sharedKey: wxacatestprofilesla.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        workloadProfileType: 'Consumption'
        name: 'Consumption'
      }
    ]
    // customDomainConfiguration: {
    //   certificatePassword: custom_domain_certificate_password
    //   certificateValue: custom_domain_cert
    //   dnsSuffix: custom_domain_name
    // }
  }
}

// Private DNS Zones for internal ACA environment - custom 
resource privateDNScustomDomain 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: custom_domain_name
  location: 'global'
}

// link private dns to vnet
resource privateDNSlink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: wxacatestprofilesvnet.name
  location: 'global'
  parent: privateDNScustomDomain
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: wxacatestprofilesvnet.id
    }
  }
}

// Container app, external ACA, public ingress
resource webtestext 'Microsoft.App/containerApps@2024-03-01' = {
  name: caname1
  location: location
  properties: {
    environmentId: wxacatestprofilesacaenv.id
    workloadProfileName: workloadProfileName
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
    }
    template: {
      containers: [
        {
          image: 'davidxw/webtest:latest'
          name: 'webtest-ext1'
          resources: {
            cpu: 2
            memory: '8Gi'
          }
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Container app, external ACA, ingress from ACA environment only
resource webtestext2 'Microsoft.App/containerApps@2024-03-01' = {
  name: caname2
  location: location
  properties: {
    environmentId: wxacatestprofilesacaenv.id
    workloadProfileName: 'Consumption'
    configuration: {
      ingress: {
        external: false
        targetPort: 8080
      }
    }
    template: {
      containers: [
        {
          image: 'davidxw/webtest:latest'
          name: 'webtest-ext2'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Container app, internal ACA, ingress from VNet (ingress "external" in this case means from VNet)
resource webtestext1_internal 'Microsoft.App/containerApps@2024-03-01' = {
  name: caname1Internal
  location: location
  properties: {
    environmentId: wxacatestprofilesacaenv_internal.id
    workloadProfileName: 'Consumption'
    configuration: {
      ingress: {
        external: true
        targetPort: 8080
      }
    }
    template: {
      containers: [
        {
          image: 'davidxw/webtest:latest'
          name: 'webtest-int1'
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// a record for internal container app in private DNS zone
// resource aRecordCustomDomain 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
//   name: '*'
//   parent: privateDNScustomDomain
//   properties: {
//     aRecords: [
//       {
//         ipv4Address: wxacatestprofilesacaenv_internal.properties.staticIp
//       }
//     ]
//   }
// }
