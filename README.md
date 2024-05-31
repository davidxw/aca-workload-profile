# ACA Sample

Create an ACA demo with both an internal and external container app.  To deploy:

1. From the certs directory run `./generate.sh`, supplying the password when prompted.
2. Check the default input paramaters in external.bicep, especially the certificate password
2. From the root directory deploy the external.bicep file

Navigate to the public URL for the webtest-ext1 container app, and attempt to do a GET on https://webtest-int1.aca.acatest.com/api/environment

![Solution diagram](deployed.drawio.svg)

