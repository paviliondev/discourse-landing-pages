(function() {
  const themeSettings = {};

  Discourse.__container__ = {
    lookup(name) {
      if (name === "service:theme-settings") {
        return {
          registerSettings(themeId, settingsObject) {
            themeSettings[themeId] = settingsObject;
          },

          getSetting(themeId, settingsKey) {
            if (themeSettings[themeId]) {
              return themeSettings[themeId][settingsKey];
            }
            return null;
          },

          getObjectForTheme(themeId) {
            return themeSettings[themeId];
          }
        };
      }
    }
  }
})();