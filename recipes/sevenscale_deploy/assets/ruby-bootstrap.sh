#!/usr/bin/env bash
set -e

operatingsystem() {
  if [ -f /etc/fedora-release ]; then
    echo "fedora"
  elif [ -f /etc/redhat-release ]; then
    local contents="$(cat /etc/redhat-release)"
    case "$contents" in
      Scientific*Linux*)
      echo "scientific"
      ;;
      *)
      echo "redhat"
      ;;
    esac
  else
    echo "unknown"
  fi
}

install_yum_repo() {
  local os="$(operatingsystem)"

  if [ ! -f /etc/yum.repos.d/papertrail.repo ]; then
    cat <<EOF > /etc/yum.repos.d/papertrail.repo
[papertrail]
name=Papertrail Packages for Fedora \$releasever - \$basearch
baseurl=https://s3.amazonaws.com/yum.papertrailapp.com/$os/\$releasever/
enabled=1
gpgcheck=0
EOF
  fi
}

install_ree() {
  yum install --nogpgcheck -q -y ruby-enterprise-edition
}

install_rubygems() {
  local tempdir="$(mktemp -d)"
  trap "rm -rf ${tempdir}" INT TERM EXIT

  local dir="rubygems-1.6.2"
  local archive="${dir}.tgz"

  pushd "$tempdir"
  curl -O http://production.cf.rubygems.org/rubygems/${archive}
  tar zxvf ${archive}

  pushd ${dir}
  ruby setup.rb

  popd
  popd

  trap - INT TERM EXIT
}

uninstall_system_ruby() {
  local os="$(operatingsystem)"

  case "$os" in
    "fedora")
      yum erase -q -y ruby ruby-libs
      ;;
    "scientific")
      yum erase -q -y ruby ruby-libs ruby-devel
      ;;
  esac
}

install_ruby() {
  local os="$(operatingsystem)"

  case "$os" in
    "fedora")
      uninstall_system_ruby
      install_yum_repo
      install_ree
      ;;
    "scientific")
      uninstall_system_ruby
      install_yum_repo
      install_ree
      ;;
    *)
      echo "Can't install ruby on '$os'. Don't know how."
      exit 1
      ;;
  esac
}

install_ruby
