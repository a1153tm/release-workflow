#!/bin/sh
set -x
set -e

_repositories=`cat config/release.json`
_repositories=`echo ${_repositories} | jq --compact-output ".repository"`
_repositories=`echo ${_repositories} \
    | sed -e "s/,/ /g" \
    | sed -e s/\"//g \
    | sed -e "s/^\[//" | sed -e "s/\]$//"`
for _repository in ${_repositories}
do
    if [ "${_repository}" != "testtest" -a "${_repository}" != "testtest2" ]; then
      echo "Invalid repository ${_repository}."
      exit 1
    fi
done

_branch=`cat config/release.json`
_branch=`echo ${_branch} | jq ".branch"`
_branch=`echo ${_branch} | sed -e s/\"//g`

rm -fr /tmp/aaa
mkdir /tmp/aaa
cd /tmp/aaa

_tag=${DRONE_COMMIT_BRANCH}
_base_dir=`pwd`
for _repository in ${_repositories}
do
  _repository_url=https://github.com/a1153tm/${_repository}.git
  cd ${_base_dir}
  git clone ${_repository_url}
  cd ${_repository}
  set +e
  git tag -d ${_tag}_prev
  if [ $? -eq 0 ]; then
    set -e
    git push origin :${_tag}_prev
  fi
  set -e
  git tag ${_tag}_prev ${_tag}
  if [ $? -eq 0 ]; then
    set -e
    git push origin ${_tag}_prev
    git tag -d ${_tag}
    git push origin :${_tag}
  fi
  set -e
  git checkout ${_branch}
  git tag ${_tag}
  git push origin ${_tag}
done

