.PHONY: test

test: python-coverage go-coverage typescript-coverage
	@nvim --headless -c "PlenaryBustedDirectory tests/"

clean: python-clean go-clean typescript-clean

## Python
tests/languages/python/.coverage:
	@(cd tests/languages/python && \
		pipenv install && \
		pipenv run pytest --cov)

.PHONY: python-coverage python-clean
python-coverage: tests/languages/python/.coverage

python-clean:
	@(cd tests/languages/python && \
		rm -rf .pytest_cache .coverage)


## Go
tests/languages/go/coverage.out:
	@(cd tests/languages/go && \
		go test -race -covermode=atomic -coverprofile=coverage.out ./...)

.PHONY: go-coverage go-clean
go-coverage: tests/languages/go/coverage.out

go-clean:
	@(cd tests/languages/go && \
		go clean -testcache && \
		rm -f coverage.out)


## typescript
tests/languages/typescript/coverage/lcov.info:
	@(cd tests/languages/typescript && \
		npm install && \
		npx jest "--coverage" "--testLocationInResults" "--verbose" "--testNamePattern='.*'")

.PHONY: typescript-coverage typescript-clean
typescript-coverage: tests/languages/typescript/coverage/lcov.info

typescript-clean:
	@(cd tests/languages/typescript && \
		rm -rf node_modules coverage)
