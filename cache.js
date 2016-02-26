module.exports = TheCoolCache = function() {
  var x = undefined;
  return {
    set: function(value) {
      x = value;
    },
    get: function() {
      return x;
    }
  }
}
