"use strict"


lib = require __dirname + '/lib/'


if not module.parent
  eyes = require 'eyes'
  inspect = eyes.inspector maxLength: no

  request = new lib.OVirtApiRequest
    protocol: 'https'
    host: "virtmanager.tigerrr.int"
    username: 'ovirtuser@tigerrr.int'
    password: 'tigerrr2013'
  request.call (error, result) ->
    console.log error if error
    inspect result
else
  module.exports = lib