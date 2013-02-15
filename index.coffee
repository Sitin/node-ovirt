"use strict"


lib = require __dirname + '/lib/'


if not module.parent
  eyes = require 'eyes'
  inspect = eyes.inspector maxLength: no

  request = new lib.OVirtApiRequest require './private.json'
  request.call (error, result) ->
    console.log error if error
    inspect result
else
  module.exports = lib