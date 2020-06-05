#!/usr/bin/env bash

go get -u github.com/haya14busa/go-vimlparser/cmd/vimlparser
go get -u github.com/erroneousboat/slack-term

cd "$GOPATH/src/github.com/erroneousboat/slack-term" || exit
go install .
