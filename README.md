# hubot-bart-elite

Allows you to query the BART API for real time transit information.

See [`src/bart.coffee`](src/bart.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-bart-elite --save`

Then add **hubot-bart-elite** to your `external-scripts.json`:

```json
[
  "hubot-bart-elite"
]
```
## Commands

Why paint yourself into a corner?

    bart (stn|stns|station|stations) list - Requests a list of all of the BART stations.
    bart (stn|stns|station|stations) info <station> - Requests detailed information on the specified station.
    bart (stn|stns|station|stations) access <station> - Requests access/neighborhood information for the specified station.
    bart (etd|me) <station> - Requests current departure information.
    bart ver - Requests current API version information.
    bart bsa - Requests current advisory information.
    bart elev - Requests current elevator infromation.

## Examples

`hubot bart stn list` - Lists stations
`hubot bart me mont` - Current train times for Montgomery
`hubot bart me embr` - Current train times for Embarcadero
`hubot bart bsa` - Current BART service advisories
`hubot bart elev` - Current BART elevator advisories.
