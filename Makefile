## Update module document
.PHONY: doc
doc:
	v doc -o docs/ -f markdown .

## Run test
.PHONY: test
test:
	cp testdata/.env testdata/.env.parse .
	v test vdotenv_test.v
	rm .env .env.parse

## Report suspicious code constructs.
.PHONY: vet
vet:
	v vet .

## Format .v files
.PHONY: fmt
fmt:
	v fmt -w .

## Clean repository
.PHONY: clean
clean:
	rm .env .env.parse
