# external facing aca v2 with container deployed to consumption profile and egress via firewall
set -e

location=eastus
rg=aca-wlp-test
vnet="$rg-vnet"
vnetcidr="10.1.0.0/16"
caname="webtest-ext"
subnet="aca-external"
subnetcidr="10.1.1.0/24"
acaenv="$rg-acaenv"
internal=false

# creates RG, VNet and subnet
source ./acacore.sh

az containerapp env create \
  --resource-group $rg \
  --location $location \
  --name $acaenv \
  --enable-workload-profiles \
  --infrastructure-subnet-resource-id "$subnetid" \
  --internal-only $internal

az containerapp create \
  --resource-group $rg \
  --environment $acaenv \
  --name $caname \
  --target-port 80 \
  --ingress external \
  --image docker.io/davidxw/webtest:latest \
  --workload-profile-name "Consumption"  


##### firewall

az network vnet subnet create \
  --resource-group $rg \
  --vnet-name $vnet \
  --name AzureFirewallSubnet \
  --address-prefixes 10.1.2.0/24 

# firewall

fwname="$rg-fw"

az network firewall create \
    --name $fwname \
    --resource-group $rg \
    --location $location \
    --tier Basic 

az network public-ip create \
    --name "$fwname-pip" \
    --resource-group $rg \
    --location $location \
    --allocation-method static \
    --sku standard

az network firewall ip-config create \
    --firewall-name $fwname \
    --name "$fwname-config" \
    --public-ip-address "$fwname-pip" \
    --resource-group $rg \
    --vnet-name $vnet

az network firewall update \
    --name $fwname \
    --resource-group $rg 

# open firewall to all HTTP and HTTPS traffic
az network firewall network-rule create \
   --collection-name default \
   --destination-addresses "*" \
   --destination-ports 80 443 \
   --firewall-name $fwname \
   --name Allow-HTTP \
   --protocols TCP \
   --resource-group $rg \
   --priority 100 \
   --source-addresses "*" \
   --action Allow

firewallprivateip="$(az network firewall ip-config list -g $rg -f $fwname --query "[?name=='$fwname-config'].privateIpAddress" --output tsv)"

# route table

az network route-table create \
    --name "$fwname-route-table" \
    --resource-group $rg \
    --location $location \
    --disable-bgp-route-propagation true

az network route-table route create \
  --name "route-to-$fwname" \
  --resource-group $rg \
  --route-table-name "$fwname-route-table" \
  --address-prefix "0.0.0.0/0" \
  --next-hop-type VirtualAppliance \
  --next-hop-ip-address $firewallprivateip

  az network vnet subnet update \
    -n $subnet \
    -g $rg \
    --vnet-name $vnet \
    --route-table "$fwname-route-table"

firewallpublicip=$(az network public-ip show --name "$fwname-pip" --resource-group $rg --query ipAddress -o tsv)
cafqdn=$(az containerapp show -n $caname -g $rg --query properties.configuration.ingress.fqdn -o tsv)

echo Navigate to https://$cafqdn, and post a get request to "https://api.ipify.org".  Response should be the external IP of the firewall - $firewallpublicip
echo \(or run \"curl https://$cafqdn/api/get?url=https%3A%2F%2Fapi.ipify.org\" from the command line\)
echo To clean up run "az group delete --resource-group $rg"

# az group delete --resource-group $rg