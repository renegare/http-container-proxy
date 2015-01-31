APP_NAME=$(notdir $(shell pwd))

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
	echo $(MAKEFILE_LIST)

#!! PROD END

clean: ## !! DELETES EVERYTHIN LISTED IN .gitignore !!
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
	docker build -t $(APP_NAME) .
	echo Done!

	printf "Cleaning up generated files ... "
	rm -rf Makefile.prod .dockerignore
	echo Done!

	echo "Reinstalling dev deps ... "
	$(MAKE) setup DEV=1
	echo Done!

test: ## run tests
	echo TBC

env: ## display environment variables
	env

ci-setup: ## from scratch: setup and build
ci-setup: clean setup build

ci: ## from scratch; setup, build, test and push (to docker hub registry)
ci: ci-setup ## test push

generate-dockerignore: ## generate ignore list (based of .gitignore + dockerignore.txt)
	cat .gitignore dockerignore.txt \
		| grep -v vendor \
		| grep -v \*\.prod

generate-makefile: ## generate makefile that contains only whats neeed to use the app
	sed -n \
		"`grep -nE "#!{2} PROD START" Makefile | cut -f1 -d:`, \
		`grep -nE "#!{2} PROD END" Makefile | cut -f1 -d:`p" \
		Makefile
