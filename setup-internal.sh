# internal facing aca v2 with container deployed to consumption profile
set -e

location=eastus
rg=aca-wlp-test-internal
vnet="$rg-vnet"
vnetcidr="10.2.0.0/16"
caname="webtest-int"
subnet="aca-internal"
subnetcidr="10.2.1.0/24"
acaenv="$rg-acaenv"
internal=true

# creates RG, VNet, ACA env, and subnet
source ./acacore.sh

az containerapp create \
  --resource-group $rg \
  --environment $acaenv \
  --name $caname \
  --target-port 80 \
  --ingress external \
  --image docker.io/davidxw/webtest:latest \
  --workload-profile-name "Consumption"  

echo To clean up run "az group delete --resource-group $rg"