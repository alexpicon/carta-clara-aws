# Carta Clara — backend build shortcuts (KODA-11)
#
#   make vendor   copy helpers.py + Sage's prompts into each handler dir
#   make build    vendor, then sam build
#   make deploy   vendor, sam build, sam deploy
#   make test     run the pytest smoke suite
#   make clean    remove build artifacts and vendored prompt dirs

.PHONY: vendor build deploy test clean

vendor:
	./scripts/vendor_prompts.sh

build: vendor
	sam build

deploy: build
	sam deploy

test:
	python -m pytest tests/ -v

clean:
	rm -rf .aws-sam .pytest_cache
	find src -type d -name prompts -exec rm -rf {} +
	find src -type d -name __pycache__ -exec rm -rf {} +
