%global install_dir /opt/gdc/zuul

Name:             zuul
Summary:          GoodData customized Zuul gatekeeper
Epoch:            1
Version:          2.1.1
Release:          6.gdc

Vendor:           GoodData
Group:            GoodData/Tools

License:          Apache
URL:              https://github.com/gooddata/zuul
Source0:          sources.tar
BuildArch:        x86_64
BuildRoot:        %{_tmppath}/%{name}-%{version}-root

Requires:         python-virtualenv

%prep
%setup -q -c

%install
rm -fr $RPM_BUILD_ROOT
mkdir -p $RPM_BUILD_ROOT%{install_dir}
cp -a * $RPM_BUILD_ROOT%{install_dir}

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

%changelog
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
