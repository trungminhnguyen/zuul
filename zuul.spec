%global install_dir /opt/gdc/zuul

Name:             zuul
Summary:          GoodData customized Zuul gatekeeper
Version:          2.1.1
Release:          1.gdc

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
* Wed Aug 12 2015 Yury Tsarev <yury.tsarev@gooddata.com> 2.1.1-1.gdc
- First Zuul build - customized github integration included
