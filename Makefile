.PHONY: test

test: python-coverage go-coverage
	@nvim --headless -c "PlenaryBustedDirectory tests/"

tests/languages/python/.coverage:
	@(cd tests/languages/python && \
		pipenv install && \
		pipenv run pytest --cov)

python-coverage: tests/languages/python/.coverage

tests/languages/go/coverage.out:
	@(cd tests/languages/go && \
		go test -race -covermode=atomic -coverprofile=coverage.out ./...)

go-coverage: tests/languages/go/coverage.out
