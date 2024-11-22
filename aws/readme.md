# IdP-init SAML solution

## Prepare
```bash
cp terraform.sample.tfvars terraform.auto.tfvars
```

edit `terraform.auto.tfvars` for your tenant.

## Deploy
```bash
make init
make
make apply
make lambda-deployment-package.zip
```

## Monitor
```bash
make log
```

## Invoke
edit `issue.sh` file and update `WORKER_BASE_URL` to `saml_api_endpoint` output from terraform.  

```bash
./issue.sh 123
```
Open the browser and past URL.