.PHONY: build tag run stop init apply push destroy clean

#
# to run:
#   AUDITR_CONFIG_URL=https://config.auditr.io AUDITR_API_KEY=prik_xxx \
#     ACCOUNT={aws-account} REGION=us-west-2 PROFILE={aws-profile} make run
# 
# or w a .env file:
#   env $(cat .env | xargs) make build
#   env $(cat .env | xargs) make tag
#   env $(cat .env | xargs) make run
#   env $(cat .env | xargs) make stop
#   env $(cat .env | xargs) make init
#   env $(cat .env | xargs) make apply
#   env $(cat .env | xargs) make push
#
# clean up:
#   env $(cat .env | xargs) make destroy
#   env $(cat .env | xargs) make clean
#
IMAGE = gmuxdemo
REPO = $(IMAGE)-dev

run:
	docker run -d --rm --name $(IMAGE) -p 8000:8000 \
		-e AUDITR_CONFIG_URL=$(AUDITR_CONFIG_URL) \
		-e AUDITR_API_KEY=$(AUDITR_API_KEY) \
		$(IMAGE)

build:
	docker image build -t $(IMAGE) .

tag:
	docker image tag $(IMAGE):latest $(ACCOUNT).dkr.ecr.$(REGION).amazonaws.com/$(REPO):latest

push:
	aws ecr get-login-password --profile $(PROFILE) | \
		docker login --username AWS --password-stdin $(ACCOUNT).dkr.ecr.$(REGION).amazonaws.com
	docker image push $(ACCOUNT).dkr.ecr.$(REGION).amazonaws.com/$(REPO):latest

stop:
	docker stop $(IMAGE)

init:
	terraform init

apply:
	terraform apply -var="config_url=$(AUDITR_CONFIG_URL)" \
		-var="api_key=$(AUDITR_API_KEY)" -var="profile=$(PROFILE)"

destroy:
	terraform destroy -var="config_url=$(AUDITR_CONFIG_URL)" \
		-var="api_key=$(AUDITR_API_KEY)" -var="profile=$(PROFILE)"

clean:
	docker rmi $(IMAGE)
	docker rmi $(ACCOUNT).dkr.ecr.$(REGION).amazonaws.com/$(REPO):latest