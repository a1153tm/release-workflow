#!/bin/sh
set -x
set -e

_repositories=`cat config/release.json | jq --compact-output ".repository"`
echo ${_repositories}
_repositories=`echo $_repositories | sed -e "s/,/ /g" | sed -e s/\"//g | sed -e "s/^\[//" |  sed -e "s/\]$//"`
echo ${_repositories}
for _repository in ${_repositories}
do
    if [ "${_repository}" != "testtest" -a "${_repository}" != "testtest2" ]; then
      echo "Invalid repository ${_repository}."
      exit 1
    fi
done

rm -fr /tmp/aaa
mkdir /tmp/aaa

_branch=`cat config/release.json | jq ".branch" | sed -e s/\"//g`

cd /tmp/aaa

_tag=${DRONE_COMMIT_BRANCH}
for _repository in ${_repositories}
do
  _repository_url=https://github.com/a1153tm/${_repository}.git
  git clone ${_repository_url}
  cd ${_repository}
  set +e
  git tag -d ${_tag}_prev
  if [ $? -eq 0 ]; then
    git push origin :${_tag}_prev
  fi
  git tag ${_tag}_prev ${_tag}
  if [ $? -eq 0 ]; then
    git push origin ${_tag}_prev
    git tag -d ${_tag}
    git push origin :${_tag}
  fi
  set -e
  git checkout ${_branch}
  git tag ${_tag}
  git push origin ${_tag}
done

