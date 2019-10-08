ROOT_DIR = $(CURDIR)
BUILD_DIR = $(ROOT_DIR)/build
DIST_DIR = $(ROOT_DIR)/dist
SRC_DIR = $(ROOT_DIR)/liqueur
PKGINFO_DIR = $(ROOT_DIR)/liqueur.egg-info
CHANGELOG_FILE = $(ROOT_DIR)/CHANGELOG.md
VERSION_FILE = $(ROOT_DIR)/.version
PACKAGE_FILE = $(ROOT_DIR)/.package
TEST_FILE = $(ROOT_DIR)/.test


$(VERSION_FILE):
	@cat $(SRC_DIR)/__init__.py | grep "__version__" | \
		sed 's/"//g' | awk -F " = " '{print $$2}' > $(VERSION_FILE)

version: $(VERSION_FILE)

gen_package: $(VERSION_FILE)
	@python setup.py sdist
	@python setup.py bdist_wheel

$(PACKAGE_FILE):
	@make gen_package
	@touch $(PACKAGE_FILE)

package: $(VERSION_FILE) $(PACKAGE_FILE)

upload_testpypi: $(PACKAGE_FILE)
	@twine upload --repository testpypi \
		$(DIST_DIR)/liqueur-`cat $(VERSION_FILE)`-py3-none-any.whl \
		$(DIST_DIR)/liqueur-`cat $(VERSION_FILE)`.tar.gz

test_install: upload_testpypi
	@pip install -i https://test.pypi.org/simple/ liqueur

$(TEST_FILE):
	@make upload_testpypi
	@make test_install
	@touch $(TEST_FILE)

test: $(TEST_FILE)

publish: $(PACKAGE_FILE) test
	@twine upload \
		$(DIST_DIR)/liqueur-`cat $(VERSION_FILE)`-py3-none-any.whl \
		$(DIST_DIR)/liqueur-`cat $(VERSION_FILE)`.tar.gz

clean:
	@rm -rf $(BUILD_DIR) $(DIST_DIR) $(PKGINFO_DIR)
	@rm -f $(VERSION_FILE) $(PACKAGE_FILE) $(TEST_FILE)

changelog: $(VERSION_FILE)
	@cp $(CHANGELOG_FILE) $(CHANGELOG_FILE).org
	@echo -e '# Changelog\n' > $(CHANGELOG_FILE)
	@echo -e '## '`cat $(VERSION_FILE)`'\n' >> $(CHANGELOG_FILE)
	@echo -e '### Feature {#feat_'`cat $(VERSION_FILE) | sed 's/\./_/g'`}'\n' >> \
		$(CHANGELOG_FILE)
	@git log origin/master..HEAD --no-merges --pretty=format:'* %s' | grep 'feat' >> \
		$(CHANGELOG_FILE)
	@echo -e '\n### Bug fixes {#fix_'`cat $(VERSION_FILE) | sed 's/\./_/g'`}'\n' >> \
		$(CHANGELOG_FILE)
	@git log origin/master..HEAD --no-merges --pretty=format:'* %s' | grep 'fix' >> \
		$(CHANGELOG_FILE)
	@sed -e '1d' $(CHANGELOG_FILE).org >> $(CHANGELOG_FILE)
	@rm $(CHANGELOG_FILE).org

.PHONY: version package test publish clean changelog