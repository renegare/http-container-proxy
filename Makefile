
#!! PROD START
help:           ## Show this help.
	@echo "\n\
      __   __  \n\
|__| /    |__) \n\
|  | \__  |    \n\
               \n\
(Http Container Proxy) \n\
               \n\
Available Make tasks: \n"
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/\\$$//' | sed -e 's/##//'; \
#!! PROD END


