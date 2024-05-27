# external facing aca v2 with container deployed to a Dedicated-D8 workload profile
set -e

location=australiaEast
rg=wx-aca-test-profiles
vnet="$rg-vnet"
vnetcidr="10.1.0.0/16"
caname1="webtest-ext1"
caname2="webtest-ext2"
subnet="aca-external"
subnetcidr="10.1.1.0/24"
acaenv="$rg-acaenv"
internal=false
la="$rg-la"

# creates RG, VNet and subnet
source ./acacore.sh

az monitor log-analytics workspace create -g $rg -n $la

la_id=$(az monitor log-analytics workspace show --name $la --resource-group $rg --query id -o tsv)
la_key=$(az monitor log-analytics workspace get-shared-keys --resource-group $rg --workspace-name $la --query primarySharedKey -o tsv)

az containerapp env create \
  --resource-group $rg \
  --location $location \
  --name $acaenv \
  --enable-workload-profiles \
  --infrastructure-subnet-resource-id "$subnetid" \
  --internal-only $internal \
  --logs-workspace-id "$la_id" \
  --logs-workspace-key $la_key

az containerapp env workload-profile set \
  --resource-group $rg \
  --name $acaenv \
  --workload-profile-type "D8" \
  --workload-profile-name "x8Core32Mem" \
  --min-nodes 1 \
  --max-nodes 1

az containerapp create \
  --resource-group $rg \
  --environment $acaenv \
  --name $caname1 \
  --target-port 80 \
  --ingress external \
  --image docker.io/davidxw/webtest:latest \
  --workload-profile-name "x8Core32Mem" \
  --cpu 4 \
  --memory 8Gi

  az containerapp create \
  --resource-group $rg \
  --environment $acaenv \
  --name $caname2 \
  --target-port 80 \
  --ingress external \
  --image docker.io/davidxw/webtest:latest \
  --workload-profile-name "Consumption"  \
  --cpu 1 \
  --memory 2Gi


cafqdn=$(az containerapp show -n $caname -g $rg --query properties.configuration.ingress.fqdn -o tsv)

echo Public enpoint: https://$cafqdn
echo To clean up run "az group delete --resource-group $rg"

# az group delete --resource-group $rg