#!/bin/sh

release_ctl eval --mfa "Repo.Setup.migrate/1" --argv -- "$@"
