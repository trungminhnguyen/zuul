sources:
	/usr/bin/virtualenv .venv
	. .venv/bin/activate && pip install -U pip # fails with old pip
	. .venv/bin/activate && pip install -r requirements.txt
	. .venv/bin/activate && python setup.py install
	rm -f .venv/pip-selfcheck.json
	/usr/bin/virtualenv --relocatable .venv
	cd .venv && tar cvf ../sources.tar *
clean:
	rm -rf sources.tar
