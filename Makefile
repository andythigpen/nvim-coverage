.PHONY: test

# TODO: run nvim tests
test: python-coverage

tests/languages/python/.coverage:
	@(cd tests/languages/python && \
		pipenv install && \
		pipenv run pytest --cov)

python-coverage: tests/languages/python/.coverage

