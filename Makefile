## Update module document
.PHONY: doc
doc:
	v doc -o docs/ -f markdown .

## Run test
.PHONY: test
test:
	v test vdotenv_test.v

## Run command and stdout integration tests (requires Python 3)
.PHONY: test-integration
test-integration:
	PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -p 'test_*.py'

## Report suspicious code constructs.
.PHONY: vet
vet:
	v vet .

## Format .v files
.PHONY: fmt
fmt:
	v fmt -w .

## Tests clean their own temporary directories; never delete user configuration.
.PHONY: clean
clean:
	@:
