#set -e

# internal facing aca v2 with container deployed to consumption profile.  ACA has custom suffix and private DNS.
# then create a second app environment with external access which can be used to access/test the internal app using
# the private DNS name

location=eastus
rg=aca-wlp-test-internal
vnet="$rg-vnet"
vnetcidr="10.2.0.0/16"
caname="webtest-int"
subnet="aca-internal"
subnetcidr="10.2.1.0/24"
acaenv="$rg-acaenv"
internal=true
privateDnsName="acatest.internal.com"

# creates RG, VNet and subnet
source ./acacore.sh

az containerapp env create \
  --resource-group $rg \
  --location $location \
  --name $acaenv \
  --enable-workload-profiles \
  --infrastructure-subnet-resource-id "$subnetid" \
  --internal-only $internal \
  --custom-domain-certificate-file "acatest.internal.com.pfx" \
  --custom-domain-certificate-password "P@ssword1234" \
  --custom-domain-dns-suffix "acatest.internal.com"

caprivateip=$(az containerapp env show -n $acaenv -g $rg --query properties.staticIp -o tsv)
cadefaultdomain=$(az containerapp env show -n $acaenv -g $rg --query properties.defaultDomain -o tsv)

az containerapp create \
  --resource-group $rg \
  --environment $acaenv \
  --name $caname \
  --target-port 80 \
  --ingress external \
  --image docker.io/davidxw/webtest:latest \
  --workload-profile-name "Consumption"  

# private DNS for custom domain

az network private-dns zone create \
    --resource-group $rg \
    --name $privateDnsName

az network private-dns record-set a add-record \
    --resource-group $rg \
    --record-set-name "*" \
    --zone-name $privateDnsName \
    --ipv4-address $caprivateip

az network private-dns link vnet create \
  --resource-group $rg \
  --name $vnet \
  --zone-name $privateDnsName \
  --virtual-network $vnet \
  --registration-enabled false

# private DNS for default domain - required for internal apps

az network private-dns zone create \
    --resource-group $rg \
    --name $cadefaultdomain

az network private-dns record-set a add-record \
    --resource-group $rg \
    --record-set-name "*" \
    --zone-name $cadefaultdomain \
    --ipv4-address $caprivateip

az network private-dns link vnet create \
  --resource-group $rg \
  --name $vnet \
  --zone-name $cadefaultdomain \
  --virtual-network $vnet \
  --registration-enabled false

# an external container app to test the internal container app

canameint="webtest-ext"
subnet="aca-external"
subnetcidr="10.2.2.0/24"
acaenvint="$rg-acaenv-ext"
internal=false

az network vnet subnet create \
  --resource-group $rg \
  --vnet-name $vnet \
  --name $subnet \
  --address-prefixes $subnetcidr \
  --delegations Microsoft.App/environments

subnetid=$(az network vnet subnet list --resource-group $rg --vnet-name $vnet --query "[?name=='$subnet'].id" -o tsv)

az containerapp env create \
  --resource-group $rg \
  --location $location \
  --name $acaenvint \
  --enable-workload-profiles \
  --infrastructure-subnet-resource-id "$subnetid" \
  --internal-only $internal

az containerapp create \
  --resource-group $rg \
  --environment $acaenvint \
  --name $canameint \
  --target-port 80 \
  --ingress external \
  --image docker.io/davidxw/webtest:latest \
  --workload-profile-name "Consumption"  

cafqdn=$(az containerapp show -n $canameint -g $rg --query properties.configuration.ingress.fqdn -o tsv)

echo Navigate to https://$cafqdn, and post a get request to https://$caname.$privateDnsName/api/environment.  A 200 response is expected, with SSL cert errors
echo \(or run \"curl https://$cafqdn/api/get?url=https%3A%2F%2F$caname.$privateDnsName/api/environment\" from the command line\)


echo To clean up run "az group delete --resource-group $rg"

