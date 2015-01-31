APP_NAME=$(notdir $(shell pwd))
APP_SERVICES=$(APP_NAME)
APP_VERSION=$(shell git rev-parse --short HEAD)
DOCKER_REGISTRY=$(if $(DOCKER_REGISTRY_USER),$(DOCKER_REGISTRY_USER),$(USER))/$(APP_NAME)

#!! PROD START
help: ## Show this help.
	@echo "\n\
      __   __  \n\
|__| /    |__) \n\
|  | \__  |    \n\
               \n\
(Http Container Proxy) \n\
               \n\
Available Make tasks: \n"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'; \

start: ## start application
	/usr/sbin/service php5-fpm start && nginx

#!! PROD END

clean: ## !! DELETES EVERYTHIN LISTED IN .gitignore !!
clean: env-clean
	-cat .gitignore \
	| grep -v '^\s*/' \
	| grep -v '^\s*\.\.' \
	| grep -v '^\s*\.\*' \
	| xargs rm -rf

setup: ## install dev deps
	if [ -n "$(GITHUB_API_TOKEN)" ]; then composer config github-oauth.github.com "$(GITHUB_API_TOKEN)"; fi
	composer update --no-progress --$(if $(DEV),,no-)dev -n --prefer-dist
	rm -rf auth.json

build: ## build image of application
	printf "Generate .dockerignore ... "
	$(MAKE) -s generate-dockerignore > .dockerignore
	echo Done!

	printf "Generate production Makefile ... "
	$(MAKE) -s generate-makefile > Makefile.prod
	echo Done!

	echo "Building the damn thing ... "
	docker build --force-rm=true -t $(APP_NAME) .
	docker run --rm $(APP_NAME) || true
	echo
	echo
	echo Done!

	printf "Cleaning up generated files ... "
	docker images -q -f dangling=true | xargs docker rmi || true
	rm -rf Makefile.prod .dockerignore
	echo Done!

test: ## run tests
test: test-integration

test-integration: export APPHOST=$(if $(APP_HOST),$(APP_HOST),http://$(shell $(MAKE) -s show-app-host))
test-integration:
	echo "base_url:\t\t$(APPHOST)"
	BEHAT_PARAMS='{"extensions":{"Behat\\MinkExtension":{"base_url":"$(APPHOST)"}}}' \
		vendor/bin/behat

env: ## display environment variables
	env

env-clean: env-down
	docker rmi $(APP_NAME) || true
	docker ps -a -f status=exited -q | xargs docker rm || true
	docker images -q -f dangling=true | xargs docker rmi || true

env-up: ## start app in dev environment
env-up: env-down
	docker run -dP \
	--name $(APP_NAME) $(APP_NAME) start

env-shell:
	docker exec -it $(APP_NAME) $(if $(CMD), /bin/bash -c '$(CMD)', /bin/bash)

env-down:
	-docker kill $(APP_NAME)
	-docker rm $(APP_NAME)

env-status: ## display services running
	echo Services running:
	for i in `echo $(APP_SERVICES) | tr ',' "\n"`; do \
		printf "$$i\t\t"; \
		docker inspect --format='{{.State.Running}}' $$i 2>/dev/null || echo false; \
	done

ci-setup: ## from scratch: setup and build
ci-setup: clean setup build env-up
	$(MAKE) setup DEV=1

ci: ## from scratch; setup, build, test and push (to docker hub registry)
ci: ci-setup test

tag: ## tag latest image using git sha as tag
	printf "Tagging $(APP_NAME):latest > $(DOCKER_REGISTRY):$(APP_VERSION) ... "
	docker tag -f $(APP_NAME):latest $(DOCKER_REGISTRY):$(APP_VERSION) 
	docker tag -f $(APP_NAME):latest $(DOCKER_REGISTRY):latest
	echo Done
	docker images

push: ## push latest built image to registry
	printf "Pushing $(DOCKER_REGISTRY):$(APP_VERSION) ... "
	if [ -n "$(DOCKER_REGISTRY_USER)" ]; then \
		docker login -e $(DOCKER_REGISTRY_EMAIL) -u $(DOCKER_REGISTRY_USER) -p $(DOCKER_REGISTRY_PASS) $(DOCKER_REGISTRY_HOST) https://index.docker.io/v1/; \
	fi
	docker push $(DOCKER_REGISTRY):$(APP_VERSION)
	echo Done

generate-dockerignore: ## generate ignore list (based of .gitignore + dockerignore.txt)
	cat .gitignore dockerignore.txt \
		| grep -v vendor \
		| grep -v \*\.prod

generate-makefile: ## generate makefile that contains only whats neeed to use the app
	sed -n \
		"`grep -nE "#!{2} PROD START" Makefile | cut -f1 -d:`, \
		`grep -nE "#!{2} PROD END" Makefile | cut -f1 -d:`p" \
		Makefile

show-app-host: ## if app is running, show the host
	if [ -n "$(DOCKER_HOST)" ]; then \
		printf `printf $(DOCKER_HOST)| sed -E 's/^[^0-9]+([0-9\.]+):.+$\/\1/'`:; \
		printf `docker port $(APP_NAME) 80 | sed -E 's/^.+:([0-9]+)$\/\1/'`; \
	else \
		printf `docker inspect --format {{.NetworkSettings.IPAddress}} $(APP_NAME)`; \
	fi
