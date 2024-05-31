# external facing aca v1

location=australiaeast
rg=aca-wlp-test-v1
vnet="$rg-vnet"
vnetcidr="10.3.0.0/16"
caname="webtest-int"
subnet="aca-internal"
subnetcidr="10.3.0.0/23"
acaenv="$rg-acaenv"
internal=false

# creates RG, VNet and subnet
source ./acacore.sh

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