`apm test` which is run be apm default is just:

`atom --dev --test spec`

Same as when running internally using cmd-alt-ctrl-P or the likes.

So to separate long integration tests we can have separate folders and do

`atom --dev --test spec-win-integration` locally

The windows one is now run in appveyor using custom fork of atom-ci script: 
