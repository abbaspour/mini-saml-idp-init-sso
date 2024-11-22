PLAN_FILE=idp-init-saml.plan

LOG_LEVEL=''
TF=terraform
WORKER=idp-init-lambda

main: plan

init:
	@$(TF) init -upgrade

plan: lambda-deployment-package.zip
	@TF_LOG=$(LOG_LEVEL) $(TF) plan -out $(PLAN_FILE)

apply:
	@$(TF) apply -auto-approve $(PLAN_FILE)

clean:
	rm $(PLAN_FILE)

log:
	aws logs --profile default tail --follow /aws/lambda/$(WORKER)

node_modules: package.json
	npm ci

%.zip: index.mjs node_modules private.pem cert.pem
	zip -r lambda-deployment-package.zip index.mjs node_modules private.pem cert.pem

.PHONY: clean
