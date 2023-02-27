
## Setup tools
setup:
	GO111MODULE=off	go get -u \
	github.com/Songmu/make2help/cmd/make2help

## Update module document
doc:
	v doc -o docs/ -f markdown .
	mv docs/.md docs/vdotenv.md

## Run test
test: vdotenv_test.v
	cp testdata/.env testdata/.env.parse .
	v test vdotenv_test.v
	rm .env .env.parse

## Report suspicious code constructs.
vet:
	v vet .

## Format .v files
fmt:
	v fmt -w .

## Clean repository
clean:
	rm .env .env.parse

## Show help
help:
	@make2help ${MAKEFILE_LIST}

.PHONY: format clean test help
