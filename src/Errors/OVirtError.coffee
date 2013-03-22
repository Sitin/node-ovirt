"use strict"


Errors = {}


OVirtError = class Errors.OVirtError extends Error
  constructor: (@message) ->
    @name = 'OVirtError'


module.exports = OVirtError