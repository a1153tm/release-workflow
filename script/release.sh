#!/bin/sh
set -x
set -e

_json=`cat config/release.json`

# リポジトリ名を取得する
_repositories=`echo ${_json} | jq --compact-output ".repository"`
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

# ブランチ名を取得する
_branch=`echo ${_json} | jq ".branch"`
_branch=`echo ${_branch} | sed -e s/\"//g`

rm -fr /tmp/aaa
mkdir /tmp/aaa
cd /tmp/aaa

_base_dir=`pwd`

# リポジトリをチェックアウトする。そのあとS3にアーティファクトがあるか確認する
for _repository in ${_repositories}
do
  _repository_url=https://github.com/a1153tm/${_repository}.git
  cd ${_base_dir} && git clone ${_repository_url} && cd ${_repository}
  git checkout ${_branch}
  _commit=`git log -1 | head -1 | cut -f2 -d " "`
  _s3_url=s3://backet/${_repository}/${_commit}.jar
  echo $_s3_url
done

# タグを打つ
_tag=${DRONE_COMMIT_BRANCH}
for _repository in ${_repositories}
do
  cd ${_base_dir}/${_repository}
  # xxx_release_prevタグを削除する
  set +e
  git tag -d ${_tag}_prev
  if [ $? -eq 0 ]; then
    set -e
    git push origin :${_tag}_prev
  fi
  # xxx_releaseタグをxxx_release_prevタグにリネームする
  set +e
  git tag ${_tag}_prev ${_tag}
  if [ $? -eq 0 ]; then
    set -e
    git push origin ${_tag}_prev
    git tag -d ${_tag}
    git push origin :${_tag}
  fi
  # releaseブランチの最終コミットにxxx_releaseタグを打つ
  set -e
  git checkout ${_branch}
  git tag ${_tag}
  git push origin ${_tag}
done

