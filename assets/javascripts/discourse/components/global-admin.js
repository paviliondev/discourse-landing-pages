import Component from "@ember/component";
import { action } from "@ember/object";
import { or } from "@ember/object/computed";
import LandingPageGlobal from "../models/landing-page-global";

export default Component.extend({
  updatingGlobal: or("destroyingGlobal", "savingGlobal"),

  didReceiveAttrs() {
    this.initializeProps();
  },

  initializeProps() {
    this.setProperties({
      scripts: this.global?.scripts,
      jsonHeader: JSON.stringify(this.global?.header || undefined, null, 4),
      jsonFooter: JSON.stringify(this.global?.footer || undefined, null, 4),
    });
  },

  @action
  saveGlobal() {
    this.setProperties({
      savingGlobal: true,
      jsonHeaderError: null,
      jsonFooterError: null,
    });

    let header;
    try {
      header = JSON.parse(this.jsonHeader || "null");
    } catch (e) {
      this.set("jsonHeaderError", e.message);
    }

    let footer;
    try {
      footer = JSON.parse(this.jsonFooter || "null");
    } catch (e) {
      this.set("jsonFooterError", e.message);
    }

    if (this.jsonHeaderError || this.jsonFooterError) {
      this.setProperties({
        savingGlobal: false,
        resultIcon: "xmark",
      });
      setTimeout(() => this.set("resultIcon", null), 10000);
      return;
    }

    const data = {
      global: {
        scripts: this.scripts,
        header,
        footer,
      },
    };

    LandingPageGlobal.save(data)
      .then((result) => {
        if (result.success) {
          this.setProperties({
            resultIcon: "check",
            global: data.global,
          });
          this.initializeProps();
        } else {
          this.set("resultIcon", "xmark");
        }
        setTimeout(() => this.set("resultIcon", null), 10000);
      })
      .finally(() => this.set("savingGlobal", false));
  },

  @action
  destroyGlobal() {
    this.set("destroyingGlobal", true);

    LandingPageGlobal.destroy()
      .then((result) => {
        if (result.success) {
          this.setProperties({
            resultIcon: "check",
            global: {},
          });
          this.initializeProps();
        } else {
          this.set("resultIcon", "xmark");
        }
        setTimeout(() => this.set("resultIcon", null), 10000);
      })
      .finally(() => this.set("destroyingGlobal", false));
  },
});
