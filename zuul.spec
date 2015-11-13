%global install_dir /opt/gdc/zuul

Name:             zuul
Summary:          GoodData customized Zuul gatekeeper
Epoch:            1
Version:          2.1.1
Release:          18.gdc

Vendor:           GoodData
Group:            GoodData/Tools

License:          Apache
URL:              https://github.com/gooddata/zuul
Source0:          sources.tar
BuildArch:        x86_64
BuildRoot:        %{_tmppath}/%{name}-%{version}-root

Requires:         python-virtualenv
BuildRequires:    python-virtualenv
BuildRequires:    libffi-devel
BuildRequires:    openssl-devel

%prep
%setup -q -c

%build
export PBR_VERSION="%{version}-%{release}"
make build

%install
rm -fr $RPM_BUILD_ROOT
make DESTDIR=$RPM_BUILD_ROOT%{install_dir} install

%clean
rm -rf $RPM_BUILD_ROOT

%description
GoodData customized Zuul gatekeeper

%files
%attr(0755, root, root) %dir %{install_dir}
%attr(0755, root, root) %{install_dir}/bin
%attr(0755, root, root) %{install_dir}/include
%attr(0755, root, root) %{install_dir}/lib
%attr(0755, root, root) %{install_dir}/lib64
%attr(0755, root, root) %{install_dir}/status

%changelog
* Thu Nov 13 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-18.gdc
- Fix zuul-merger not creating the git_dir on start, which fails on new deployments
- Sync with upstream changes (from now only merges into this repo, no rebases)

* Thu Nov 13 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-17.gdc
- Respect PPID umask when daemonizing

* Thu Nov 13 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-16.gdc
- Package 2.1.1-15 was mistakenly built on top of 2.1.1-14 instead of
  2.1.1-14.1. Rebuild with the correct content.

* Thu Nov 10 2015 Yury Tsarev <yury.tsarev@gooddata.com> 2.1.1-15.gdc
- Include web assets into package

* Wed Nov 03 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-14.1.gdc
- Fix the backward compatibility
- Fix the layout validation tool until upstream does

* Wed Nov 03 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-14.gdc
- Rebase onto upstream changes
- Change of the github reporter defaults
- Change name of configuration option in github reporter (backwards compatible)
- Change in the ssh configuration
- Built on top of:
  git fetch https://github.com/gooddata/zuul refs/heads/compat/github-integration-status

* Wed Nov 03 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-13.gdc
- github3.py >=1.0.0 has different API, fix a bug resulting from such incompatibility
- Built on top of:
  git fetch https://github.com/gooddata/zuul refs/heads/not-in-review/github-integration/5

* Wed Nov 03 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-12.gdc
- Support merging pull requests from github reporter
- Depend on pre-release version on github3.py 1.0.0a2 (fixes merging PRs)
- Built on top of:
  git fetch https://github.com/gooddata/zuul refs/heads/not-in-review/github-integration/4

* Wed Oct 29 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-11.gdc
- Fix minor test glitch
- Update authorship of commits
- Built on top of:
  git fetch https://github.com/gooddata/zuul refs/heads/not-in-review/github-integration/3

* Wed Oct 27 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-10.gdc
- Enforce the config schema of the github reporter
- Built on top of:
  git fetch https://github.com/gooddata/zuul refs/heads/not-in-review/github-integration/2

* Wed Oct 27 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-9.gdc
- Make the github statuses configurable, with sane defaults
- Improve the github statuses & comment testing
- Fix github-ssh documentation
- Built on top of:
  git fetch https://github.com/gooddata/zuul refs/heads/not-in-review/github-integration/1

* Wed Oct 26 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-8.gdc
- Set Github statuses
- Built on top of:
  git fetch https://review.openstack.org/openstack-infra/zuul refs/changes/03/239303/6 && git checkout FETCH_HEAD

* Wed Oct 26 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-7.gdc
- Fix SSH URL
- Built on top of:
  git fetch https://review.openstack.org/openstack-infra/zuul refs/changes/38/239138/7 && git checkout FETCH_HEAD

* Wed Oct 26 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-6.gdc
- Allow access to private repositories via SSH
- Built on top of:
  git fetch https://review.openstack.org/openstack-infra/zuul refs/changes/38/239138/6 && git checkout FETCH_HEAD

* Wed Oct 26 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-5.gdc
- Fix the construction of messages in the reporter
- Built on top of:
  git fetch https://review.openstack.org/openstack-infra/zuul refs/changes/03/239203/5 && git checkout FETCH_HEAD

* Wed Oct 26 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-4.gdc
- Fix the pr-comment handling
- More debugging output
- Built on top of:
  git fetch https://review.openstack.org/openstack-infra/zuul refs/changes/03/239203/4 && git checkout FETCH_HEAD

* Wed Oct 26 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-3.gdc
- Support to trigger jobs on github pull request comments
- GitHub change support for patchset
- Link to pull request in job descriptions
- Built on top of:
  git fetch https://review.openstack.org/openstack-infra/zuul refs/changes/03/239203/3 && git checkout FETCH_HEAD

* Wed Sep 14 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1.dev76-1.gdc
- Adding GitHub tests
- Base versioning scheme on `zuul --version'

* Wed Aug 12 2015 Jan Hruban <jan.hruban@gooddata.com> 2.1.1-2.gdc
- Better webhook event handling in the github integration

* Wed Aug 12 2015 Yury Tsarev <yury.tsarev@gooddata.com> 2.1.1-1.gdc
- First Zuul build - customized github integration included
