"use strict"


Mixins = {}

#
# Mixin for working with properties.
#
# @mixin
#
Mixins.PropertyDistributor =
  #
  # Sets values for existed properties (including private).
  #
  # @param properties [Object] property values
  #
  # @return [Object] current instance
  #
  setupExistedProperties: (properties) ->
    # We need only properties those are in the prototype
    for key of properties
      if typeof @[key] isnt 'undefined'
        @[key] = properties[key]
      else if typeof @['_' + key] isnt 'undefined'
        # Try to set via setter if exists:
        if typeof @__lookupSetter__(key) is 'function'
          @[key] = properties[key]
        else
          @['_' + key] = properties[key]

    @


module.exports = Mixins.PropertyDistributor
