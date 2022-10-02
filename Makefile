.PHONY: test

test: python-coverage go-coverage typescript-coverage ruby-coverage
	@nvim --headless -c "PlenaryBustedDirectory tests/"

clean: python-clean go-clean typescript-clean ruby-clean

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


## Typescript
tests/languages/typescript/coverage/lcov.info:
	@(cd tests/languages/typescript && \
		npm install && \
		npx jest "--coverage" "--testLocationInResults" "--verbose" "--testNamePattern='.*'")

.PHONY: typescript-coverage typescript-clean
typescript-coverage: tests/languages/typescript/coverage/lcov.info

typescript-clean:
	@(cd tests/languages/typescript && \
		rm -rf node_modules coverage)


## Ruby
tests/languages/ruby/coverage/coverage.json:
	@(cd tests/languages/ruby && \
		bundle install && \
		bundle exec rspec)

.PHONY: ruby-coverage ruby-clean
ruby-coverage: tests/languages/ruby/coverage/coverage.json

ruby-clean:
	@(cd tests/languages/ruby && \
		rm -rf coverage vendor .rspec_status)

