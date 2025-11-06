# ACA Sample

Create an ACA demo with both an internal and external container app.  To deploy:

1. From the certs directory run `./generate.sh`, supplying the password when prompted. This will create a self-signed cert for the internal container app, and copy the pfx file to the root directory where it can be referenced by the bicep file.
2. Check the default input parameters in external.bicep, especially the certificate password (which you would have supplied in step 1).
3. From the root directory deploy the external.bicep file to an existing resource group, e.g.

```
az deployment group create --resource-group aca-test --template-file external.bicep
```

Navigate to the public URL for the webtest-ext1 container app, and attempt to do a GET on https://webtest-int1.aca.acatest.com/api/environment

![Solution diagram](deployed.drawio.svg)

