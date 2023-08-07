SPHINX_BUILDARGS=
# Note that these are keys generated by the docker rsconnect service, so are
# not really secrets. They are saved to json to make it easy to use rsconnect
# as multiple users from the tests
RSC_API_KEYS=pins/tests/rsconnect_api_keys.json

dev: pins/tests/rsconnect_api_keys.json

dev-start:
	docker-compose up -d
	docker-compose exec -T rsconnect bash < script/setup-rsconnect/add-users.sh
	# curl fails with error 52 without a short sleep....
	sleep 5
	curl -s --retry 10 --retry-connrefused http://localhost:3939

dev-stop:
	docker-compose down
	rm -f $(RSC_API_KEYS)

$(RSC_API_KEYS): dev-start
	python script/setup-rsconnect/dump_api_keys.py $@

README.md:
	quarto render README.qmd

test: test-most test-rsc

test-most:
	pytest pins -m "not fs_rsc" --workers 4 --tests-per-worker 1

test-rsc:
	pytest pins -m "fs_rsc"

docs-build:
	cd docs && python -m quartodoc build --verbose
	cd docs && quarto render

docs-clean:
	rm -rf docs/_build docs/api/api_card

requirements/dev.txt: setup.cfg
	@# allows you to do this...
	@# make requirements | tee > requirements/some_file.txt
	@pip-compile setup.cfg --rebuild --extra doc --extra test --output-file=- > $@

binder/requirements.txt: requirements/dev.txt
	cp $< $@

ci-compat-check:
	# TODO: mark as dummy
	$(MAKE) -C script/$@
