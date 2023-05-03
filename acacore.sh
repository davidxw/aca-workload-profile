az group create \
  --resource-group $rg \
  --location $location \
  --tags "demogroup=aca-wlp"

az network vnet create \
  --resource-group $rg \
  --location $location \
  --address-prefixes $vnetcidr \
  --name $vnet

az network vnet subnet create \
  --resource-group $rg \
  --vnet-name $vnet \
  --name $subnet \
  --address-prefixes $subnetcidr \
  --delegations Microsoft.App/environments

subnetid=$(az network vnet subnet list --resource-group $rg --vnet-name $vnet --query "[?name=='$subnet'].id" -o tsv)

