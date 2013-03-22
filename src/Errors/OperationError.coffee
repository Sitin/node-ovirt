"use strict"


Errors =
  OVirtError: require __dirname + '/OVirtError'


OperationError = class Errors.OperationError extends Errors.OVirtError
  constructor: (@responseCode, @message) ->
    super @message
    @name = 'OperationError'


module.exports = OperationError