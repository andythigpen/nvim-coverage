.PHONY: test

test: python-coverage go-coverage typescript-coverage
	@nvim --headless -c "PlenaryBustedDirectory tests/"


## Python
tests/languages/python/.coverage:
	@(cd tests/languages/python && \
		pipenv install && \
		pipenv run pytest --cov)

python-coverage: tests/languages/python/.coverage


## Go
tests/languages/go/coverage.out:
	@(cd tests/languages/go && \
		go test -race -covermode=atomic -coverprofile=coverage.out ./...)

go-coverage: tests/languages/go/coverage.out


## typescript
tests/languages/typescript/coverage/lcov.info:
	@(cd tests/languages/typescript && \
		npx jest "--coverage" "--testLocationInResults" "--verbose" "--testNamePattern='.*'")

typescript-coverage: tests/languages/typescript/coverage/lcov.info
