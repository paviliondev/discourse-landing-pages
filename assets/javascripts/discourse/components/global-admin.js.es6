import Component from "@ember/component";
import discourseComputed from "discourse-common/utils/decorators";
import { or } from "@ember/object/computed";
import LandingPageGlobal from '../models/landing-page-global';

export default Component.extend({
  classNames: 'global-admin',
  updatingGlobal: or('destroyingGlobal', 'savingGlobal'),

  didReceiveAttrs() {
    this.initializeProps();
  },

  initializeProps() {
    const props = {
      scripts: []
    };
    const global = this.global;

    if (global) {
      if (global.scripts) {
        props.scripts = global.scripts
      }

      if (global.header) {
        props.headerJSON = JSON.stringify(global.header, undefined, 4);
      }

      if (global.footer) {
        props.footerJSON = JSON.stringify(global.footer, undefined, 4);
      }
    }

    this.setProperties(props);
  },

  actions: {
    saveGlobal() {
      this.set('savingGlobal', true);

      const scripts = this.scripts;
      const headerJSON = this.headerJSON;
      const footerJSON = this.footerJSON;
      const header = headerJSON ? JSON.parse(headerJSON) : null;
      const footer = footerJSON ? JSON.parse(footerJSON) : null;
      const global = {
        scripts,
        header,
        footer
      }

      const data = { global };
      let self = this;

      LandingPageGlobal.save(data).then(result => {
        if (result.success) {
          self.setProperties({
            resultIcon: 'check',
            global
          });
          self.initializeProps();
        } else {
          self.set('resultIcon', 'times');
        }

        setTimeout(() => {
          self.set('resultIcon', null)
        }, 10000);
      }).finally(() => {
        self.set('savingGlobal', false);
      });
    },

    destroyGlobal() {
      this.set("destroyingGlobal", true);
      let self = this;

      LandingPageGlobal.destroy().then(result => {
        if (result.success) {
          self.setProperties({
            resultIcon: 'check',
            global: null,
            scripts: null,
            headerJSON: null,
            footerJSON: null
          });
        } else {
          self.set('resultIcon', 'times');
        }

        setTimeout(() => {
          self.set('resultIcon', null)
        }, 10000);
      }).finally(() => {
        self.set('destroyingGlobal', false);
      });
    }
  }
});