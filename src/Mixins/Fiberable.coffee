"use strict"


_ = require 'lodash'
Fiber = require 'fibers'


Mixins = {}

#
# Mixin for fiber support.
#
# @mixin
#
Mixins.Fiberable =
  #
  # List of fiberized methods
  #
  _$fiberized: []

  included: (methods) ->
    return unless methods?

    for name in methods
      @__defineSetter__ name, (fn) ->
        delete @[name]
        @[name] = fn
        @_$fiberize name, fn

  #
  # Fiberizes specified methods.
  #
  # @param methods [Array<String>] methods to fiberize
  #
  # @return [Object] current instance
  #
  $fiberize: (methods) ->
    for name in methods when _.isFunction @[name]
      @_$fiberize name unless name in @_$fiberized

    @

  #
  # Fiberizes specified method.
  #
  # @param name [String] method name to fiberization
  # @param source [Function] optional function value
  #
  # @return [Function] fiberized method
  #
  # @private
  #
  _$fiberize: (name, source = null) ->
    source = @[name] unless source?

    fiberized = (params..., callback) ->
      ctx = @
      fiber = Fiber.current

      fiberizedCallback = (error, results...) ->
        # Fiberized behaviour
        if fiber?
          fiber.run results...
          throw error if error?

        # Normal async behaviour
        callback error, results... if callback?

      # Perform source function
      params.push fiberizedCallback
      source.apply ctx, params

      # Return result synchroniously
      do Fiber.yield if fiber?

    @[name] = fiberized



module.exports = Mixins.Fiberable