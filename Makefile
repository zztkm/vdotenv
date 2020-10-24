
## Setup tools
setup:
	GO111MODULE=off	go get -u \
	github.com/Songmu/make2help/cmd/make2help

## Update module document
doc:
	v doc -o docs -f markdown .

## Run test
test:
	v test .

## Report suspicious code constructs.
vet:
	v vet *.v

## Format .v files
format:
	v fmt -w *.v

## Clean repository
clean:
	rm vdotenv_test

## Show help
help:
	@make2help ${MAKEFILE_LIST}

.PHONY: format clean test help
