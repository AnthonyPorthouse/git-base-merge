#!/usr/bin/env bash

version() {
  echo "Git Base Merge v0.0.2"
}

usage() {
  echo "git base-merge [options] [RELEASE]"
}

main() {
  local subcommand="$1"

  case $subcommand in
    "-v"|"--version")
      version
      exit 0
      ;;

    "-h"|"--help")
      usage
      exit 0
      ;;
  esac

  checkHasUpstream
  needsBaseMerge "$1"

  if [ "$?" -gt "0" ]; then
    echo "Base merge needed. Merging release $1"
    doBaseMerge "$1"
  else
    echo "No base merge needed"
  fi

  exit 0
}

checkHasUpstream() {
  local upstream=$(git config basemerge.repo)

  if [ "$?" -gt "0" ] || [ "$upstream" == '' ]; then
    echo "No upstream configured. Set with 'git config basemerge.repo \"git@github.com/yourname/yourrepo.git\"'"
    exit 1
  fi

  val=$(git remote -v | grep upstream | grep "$upstream" | wc -l | xargs)
  if [ "$val" -eq "0" ]; then
    addBaseUpstream
  fi
}

addBaseUpstream() {
  git remote add upstream $(git config basemerge.repo)
}

needsBaseMerge() {
  local releasePrefix=$(git config basemerge.prefix)
  local release=$(printf '%s/%s' "$releasePrefix" "$1")
  release=$(echo $release | sed -e "s/^\///")

  git fetch upstream > /dev/null
  val=$(git log "upstream/$release" --not master  --oneline | wc -l | xargs)
  if [ "$val" -gt "0" ]; then
    return 1;
  fi

  return 0;
}

doBaseMerge() {
  git checkout master > /dev/null
  git pull > /dev/null
  git checkout -b feature/base-merge-$(date '+%Y-%m-%d')
  git merge upstream/release/$1
}

main "$@"
