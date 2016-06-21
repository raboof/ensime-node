[![Build Status](https://drone.github.woodenstake.se/api/badges/hedefalk/ensime-node/status.svg)](https://drone.github.woodenstake.se/ensime/ensime-node)
[![Build Status](https://travis-ci.org/ensime/ensime-node.svg?branch=master)](https://travis-ci.org/ensime/ensime-node)

# Ensime client Node.js bindings

This is a collection of utilities for working with Ensime from a node environment. Previously part of [ensime-atom](https://github.com/ensime/ensime-atom) but broken out for reusability in for instance a planned ensime-vscode package.

## Work in progress!!! 

This package needs lot of cleanup and test coverage. The pull-out from ensime-atom was made in a rush to see that this approach was feasable so there is definitely room for improvements :)




## Temp private drone ci instructions:
drone -s https://drone.github.woodenstake.se -t TOKEN secure --repo hedefalk/ensime-node --in ../drone-secrets/secrets.yml --out .drone.sec



## TODOS:

* Tail server log externally so pipe doesn't die on client death