var rg = resourceGroup().name

var vnet ='${rg}-vnet'
var vnetCidr = '10.1.0.0/16'

var subnet = 'aca-external'
var subnetcidr = '10.1.1.0/24'

var caname1 = 'webtest-ext1'
var caname2 = 'webtest-ext2'

var acaenv = '${rg}-acaenv'
var workloadProfileName = 'x4Core16Mem'
var workloadProfileType = 'D4'
var acaInternal = false

var laws = '${rg}-la'

var location = resourceGroup().location

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

resource wxacatestprofilesla 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  location: location
  name: laws
}

resource wxacatestprofilesacaenv 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: acaenv
  location: location
  properties: {
    vnetConfiguration: {
      internal: acaInternal
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
