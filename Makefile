sources:
	/usr/bin/virtualenv .venv
	. .venv/bin/activate && pip install -U pip # fails with old pip
	. .venv/bin/activate && pip install -r requirements.txt > WTF
	. .venv/bin/activate && python setup.py install
	. .venv/bin/activate && zuul --version 2>&1 | sed 's|.*: *\(.*\)|\1|' > VERSION
	sed -e "s|@@VERSION@@|`cat VERSION`|" zuul.spec.in > zuul.spec
	rm -f .venv/pip-selfcheck.json
	/usr/bin/virtualenv --relocatable .venv
	cd .venv && tar cvf ../sources.tar *
clean:
	rm -rf sources.tar
