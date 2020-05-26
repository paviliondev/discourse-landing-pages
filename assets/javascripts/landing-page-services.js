(function() {
  var themeSettings = {};

  Discourse.__container__ = {
    lookup: function(name) {
      if (name === "service:theme-settings") {
        return {
          registerSettings: function(themeId, settingsObject) {
            themeSettings[themeId] = settingsObject;
          },

          getSetting: function(themeId, settingsKey) {
            if (themeSettings[themeId]) {
              return themeSettings[themeId][settingsKey];
            }
            return null;
          },

          getObjectForTheme: function(themeId) {
            return themeSettings[themeId];
          }
        };
      }
    }
  }
})();