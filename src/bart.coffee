# Description
#   Allows you to query the BART API for real time transit information.
#
# Commands:
#   bart (stn|stns|station|stations) list - Requests a list of all of the BART stations.
#   bart (stn|stns|station|stations) info <station> - Requests detailed information on the specified station.
#   bart (stn|stns|station|stations) access <station> - Requests access/neighborhood information for the specified station.
#   bart (etd|me) <station> - Requests current departure information.
#   bart ver - Requests current API version information.
#   bart bsa - Requests current advisory information.
#   bart elev - Requests current elevator infromation.
#
# Configuration:
#   HUBOT_BART_ELITE_SLACK - Optimize output text for Slack.
#
# Author:
#   Zachary Patten <zachary@jovelabs.com>


xml2js = require('xml2js')
util = require('util')

bart_api_key = "MW9S-E7SL-26DU-VV8V"
bart_api_url = "http://api.bart.gov/api/"

output_slack = process.env.HUBOT_BART_ELITE_SLACK

module.exports = (robot) ->

  robot.respond /bart$/i, (msg) ->
    cmds = robot.helpCommands()
    cmds = cmds.filter (cmd) -> cmd.match(new RegExp('bart'))
    msg.send cmds.join("\n")
    return


  robot.respond /bart bsa/i, (msg) ->
    strings = []
    msg.http(format_bart_api_url("bsa", "bsa")).get() (err, res, body) ->
      return msg.send format_http_error(err) if err
      (new xml2js.Parser()).parseString body, (err, json) ->
        dump_json(json)

        return msg.send format_bart_api_error(json) if is_bart_api_error(json)
        return msg.send format_bart_api_warning(json) if is_bart_api_warning(json)

        strings.push "*BART ADVISORY INFORMATION*"
        strings.push "```" if output_slack
        if json['root']['bsa']
          if json['root']['bsa'] instanceof Array
            for bsa in json['root']['bsa']
              strings.push format_bart_bsa(bsa)
          else
            strings.push format_bart_bsa(json['root']['bsa'])
        else
          strings.push "No advisory information is available at this time!"
        strings.push "```" if output_slack
        msg.send strings.join('\n')


  robot.respond /bart elev/i, (msg) ->
    strings = []
    msg.http(format_bart_api_url("bsa", "elev")).get() (err, res, body) ->
      return msg.send format_http_error(err) if err
      (new xml2js.Parser()).parseString body, (err, json) ->
        dump_json(json)

        return msg.send format_bart_api_error(json) if is_bart_api_error(json)
        return msg.send format_bart_api_warning(json) if is_bart_api_warning(json)

        strings.push "*BART ELEVATOR INFORMATION*"
        strings.push "```" if output_slack
        if json['root']['bsa']
          if json['root']['bsa'] instanceof Array
            for bsa in json['root']['bsa']
              strings.push format_bart_bsa(bsa)
          else
            strings.push format_bart_bsa(json['root']['bsa'])
        else
          strings.push "No elevator information is available at this time!"
        strings.push "```" if output_slack
        msg.send strings.join('\n')


  robot.respond /bart (stn|stns|station|stations) (list|access|info)\s*(.*)?$/i, (msg) ->
    strings = []
    action = msg.match[2]
    stn = msg.match[3]

    if action.match /list/i
      msg.http(format_bart_api_url("stn", "stns")).get() (err, res, body) ->
        return msg.send format_http_error(err) if err
        (new xml2js.Parser()).parseString body, (err, json) ->
          dump_json(json)
          return msg.send format_bart_api_error(json) if is_bart_api_error(json)
          return msg.send format_bart_api_warning(json) if is_bart_api_warning(json)

          strings.push "*BART STATION LIST*"
          strings.push "```" if output_slack
          for station in json['root']['stations'][0]['station']
            strings.push "  #{station['abbr'][0]} - #{station['name'][0]} (#{station['address'][0]}, #{station['city'][0]}, #{station['state'][0]} #{station['zipcode'][0]})"
          strings.push "```" if output_slack
          msg.send strings.join('\n')

    if action.match /info/i
      return msg.send "ERROR: You must specify a station to get information for it!" if stn == ''
      return msg.send "ERROR: You must specify a station to get information for it!" if msg.match[3] is undefined
      msg.http(format_bart_api_url("stn", "stninfo", ["orig=#{msg.match[3].toUpperCase()}"])).get() (err, res, body) ->
        return msg.send format_http_error(err) if err
        (new xml2js.Parser()).parseString body, (err, json) ->
          dump_json(json)
          return msg.send format_bart_api_error(json) if is_bart_api_error(json)
          return msg.send format_bart_api_warning(json) if is_bart_api_warning(json)

          info = json['root']['stations'][0]['station'][0]
          strings.push "===== BART STATION INFORMATION ====="
          strings.push "```" if output_slack
          strings.push "#{info['name']} (#{info['abbr']}) [#{info['link']}]"
          strings.push "#{info['address']}"
          strings.push "#{info['city']}, #{info['state']}  #{info['zipcode']}"
          if info['north_platforms']['platform']
            strings.push "North Platform: #{info['north_platforms']['platform']}"
            if info['north_routes']['route']
              for route in info['north_routes']['route']
                strings.push "  #{route}"
          if info['south_platforms']['platform']
            strings.push "South Platform: #{info['south_platforms']['platform']}"
            if info['south_routes']['route']
              for route in info['south_routes']['route']
                strings.push "  #{route}"
          strings.push info['platform_info'] if info['platform_info']
          strings.push info['intro'] if info['intro']
          strings.push "Cross-Street: #{info['cross_street']}" if info['cross_street']
          strings.push "#{info['name']} Food: #{info['food']}" if info['food']
          strings.push "#{info['name']} Shopping: #{info['shopping']}" if info['shopping']
          strings.push "#{info['name']} Attractions: #{info['attraction']}" if info['attraction']
          strings.push "```" if output_slack
          msg.send strings.join('\n')

    if action.match /access/i
      return msg.send "ERROR: You must specify a station to get access information for it!" if stn == ''
      msg.http(format_bart_api_url("stn", "stnaccess", ["orig=#{msg.match[3].toUpperCase()}"])).get() (err, res, body) ->
        return msg.send format_http_error(err) if err
        (new xml2js.Parser()).parseString body, (err, json) ->
          dump_json(json)
          return msg.send format_bart_api_error(json) if is_bart_api_error(json)
          return msg.send format_bart_api_warning(json) if is_bart_api_warning(json)

          strings = []
          strings.push "*BART STATION ACCESS INFORMATION*"
          msg.send strings.join('\n')


  robot.respond /bart (ver|version)/i, (msg) ->
    msg.http(format_bart_api_url("etd", "ver")).get() (err, res, body) ->
      return msg.send format_http_error(err) if err
      (new xml2js.Parser()).parseString body, (err, json) ->
        dump_json(json)
        return msg.send format_bart_api_error(json) if is_bart_api_error(json)
        return msg.send format_bart_api_warning(json) if is_bart_api_warning(json)

        strings = []
        strings.push "```" if output_slack
        strings.push "API Version: #{json['root']['apiVersion']}"
        strings.push "Copyright: #{json['root']['copyright']}"
        strings.push "License: #{json['root']['license']}"
        strings.push "```" if output_slack
        msg.send strings.join('\n')


  robot.respond /bart (etd|me) (.*)/i, (msg) ->
    msg.http(format_bart_api_url("etd", "etd", ["orig=#{msg.match[2].toUpperCase()}"])).get() (err, res, body) ->
      return msg.send format_http_error(err) if err
      (new xml2js.Parser()).parseString body, (err, json) ->
        dump_json(json)
        return msg.send format_bart_api_error(json) if is_bart_api_error(json)
        return msg.send format_bart_api_warning(json) if is_bart_api_warning(json)

        strings = []
        for station in json['root']['station']
          strings.push "*BART ESTIMATED DEPARTURES FOR #{station['abbr'][0].toUpperCase()}* (#{station['name'][0].toUpperCase()})"
          strings.push "```" if output_slack
          if station['etd'] instanceof Array
            for etd in station['etd']
              strings.push process_bart_etd etd
          else
            if station['etd']
              strings.push process_bart_etd station['etd']
            else
              strings.push "No trains running!"
          strings.push "```" if output_slack
        msg.send strings.join('\n')


is_bart_api_error = (json) ->
  return true if json['message'] and json['message']['error'] and json['message']['error']['text'] and json['message']['error']['text'] != ''
  return false

is_bart_api_warning = (json) ->
  return true if json['message'] and json['message']['warning'] and json['message']['warning'] != ''
  return false

dump_json = (json) ->
  console.log(util.inspect(json, false, null))

process_bart_etd = (etd) ->
  strings = []
  strings.push "  #{etd['abbreviation']} (#{etd['destination']})"
  if etd['estimate'] instanceof Array
    for estimate in etd['estimate']
      strings.push format_bart_etd estimate
  else
    strings.push format_bart_etd etd['estimate']
  strings.join('\n')

format_bart_etd = (estimate) ->
  "    #{estimate['minutes']}#{if estimate['minutes'] != 'Leaving' then 'm' else ''}, #{estimate['length']} Car, #{estimate['direction']}bound, Platform #{estimate['platform']} (#{if estimate['bikeflag'] == 1 then 'Bikes OK' else 'NO Bikes'})"

format_bart_api_url = (uri, cmd, add) ->
  url = "#{bart_api_url}#{uri}.aspx?cmd=#{cmd}&key=#{bart_api_key}#{if add then '&'+add.join('&') else ''}"
  console.log("format_bart_api_url(): '#{url}'")
  url

format_http_error = (err) ->
  "HTTP ERROR: #{err}"

format_bart_api_error = (json) ->
  "BART API ERROR: #{json['message']['error']['text']} (#{json['message']['error']['details']})"

format_bart_api_warning = (json) ->
  "BART API WARNING: #{json['message']['warning']}"

format_bart_bsa = (bsa) ->
  message = []
  message.push "#{bsa['type']}" if bsa['type']
  message.push "##{bsa['@']['id']}" if bsa['@'] and bsa['@']['id']
  message.push "@ #{bsa['posted']}" if bsa['posted']
  message.push "\n    " if message.length > 0
  message.push "#{bsa['description']}"
  "  #{message.join(' ')}"
