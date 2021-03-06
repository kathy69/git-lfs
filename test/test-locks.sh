#!/usr/bin/env bash

. "test/testlib.sh"

begin_test "list a single lock"
(
  set -e

  setup_remote_repo_with_file "locks_list_single" "f.dat"

  GITLFSLOCKSENABLED=1 git lfs lock "f.dat" | tee lock.log

  id=$(grep -oh "\((.*)\)" lock.log | tr -d "()")
  assert_server_lock $id

  GITLFSLOCKSENABLED=1 git lfs locks --path "f.dat" | tee locks.log
  grep "1 lock(s) matched query" locks.log
  grep "f.dat" locks.log
)
end_test

begin_test "list locks with a limit"
(
  set -e

  reponame="locks_list_limit"
  setup_remote_repo "remote_$reponame"
  clone_repo "remote_$reponame" "clone_$reponame"

  git lfs track "*.dat"
  echo "foo" > "g_1.dat"
  echo "bar" > "g_2.dat"

  git add "g_1.dat" "g_2.dat" ".gitattributes"
  git commit -m "add files" | tee commit.log
  grep "3 files changed" commit.log
  grep "create mode 100644 g_1.dat" commit.log
  grep "create mode 100644 g_2.dat" commit.log
  grep "create mode 100644 .gitattributes" commit.log


  git push origin master 2>&1 | tee push.log
  grep "master -> master" push.log

  GITLFSLOCKSENABLED=1 git lfs lock "g_1.dat" | tee lock.log
  assert_server_lock "$(grep -oh "\((.*)\)" lock.log | tr -d "()")"

  GITLFSLOCKSENABLED=1 git lfs lock "g_2.dat" | tee lock.log
  assert_server_lock "$(grep -oh "\((.*)\)" lock.log | tr -d "()")"

  GITLFSLOCKSENABLED=1 git lfs locks --limit 1 | tee locks.log
  grep "1 lock(s) matched query" locks.log
)
end_test

begin_test "list locks with pagination"
(
  set -e

  reponame="locks_list_paginate"
  setup_remote_repo "remote_$reponame"
  clone_repo "remote_$reponame" "clone_$reponame"

  git lfs track "*.dat"
  for i in $(seq 1 5); do
    echo "$i" > "h_$i.dat"
  done

  git add "h_1.dat" "h_2.dat" "h_3.dat" "h_4.dat" "h_5.dat" ".gitattributes"

  git commit -m "add files" | tee commit.log
  grep "6 files changed" commit.log
  for i in $(seq 1 5); do
    grep "create mode 100644 h_$i.dat" commit.log
  done
  grep "create mode 100644 .gitattributes" commit.log

  git push origin master 2>&1 | tee push.log
  grep "master -> master" push.log

  for i in $(seq 1 5); do
    GITLFSLOCKSENABLED=1 git lfs lock "h_$i.dat" | tee lock.log
    assert_server_lock "$(grep -oh "\((.*)\)" lock.log | tr -d "()")"
  done

  # The server will return, at most, three locks at a time
  GITLFSLOCKSENABLED=1 git lfs locks --limit 4 | tee locks.log
  grep "4 lock(s) matched query" locks.log
)
end_test
