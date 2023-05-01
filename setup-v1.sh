# internal facing aca v2 with container deployed to consumption profile
set -e

location=australiaeast
rg=aca-wlp-test-v1
vnet="$rg-vnet"
vnetcidr="10.3.0.0/16"
caname="webtest-int"
subnet="aca-internal"
subnetcidr="10.3.0.0/23"
acaenv="$rg-acaenv"
internal=false

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
  --address-prefixes $subnetcidr 

subnetid=$(az network vnet subnet list --resource-group $rg --vnet-name $vnet --query "[?name=='$subnet'].id" -o tsv)

az containerapp env create \
  --resource-group $rg \
  --location $location \
  --name $acaenv \
  --infrastructure-subnet-resource-id "$subnetid" \
  --internal-only $internal

az containerapp create \
  --resource-group $rg \
  --environment $acaenv \
  --name $caname \
  --target-port 80 \
  --ingress external \
  --image docker.io/davidxw/webtest:latest 

cafqdn=$(az containerapp show -n $caname -g $rg --query properties.configuration.ingress.fqdn -o tsv)

echo Public enpoint: https://$cafqdn
echo To clean up run "az group delete --resource-group $rg"