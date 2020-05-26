import LandingPage from '../models/landing-page';
import { ajax } from 'discourse/lib/ajax';
import DiscourseRoute from "discourse/routes/discourse";
import { set } from "@ember/object";

export default DiscourseRoute.extend({
  model(params) {
    return LandingPage.all();
  },
  
  afterModel(model) {
    return this._getThemes(model);
  },

  setupController(controller, model) {        
    controller.setProperties({
      pages: model.pages,
      themes: model.themes
    });
  },
  
  _getThemes(model) {
    return ajax('/admin/themes')
      .then((result) => {
        set(model, 'themes', result.themes.map(t => {
          return {
            id: t.id,
            name: t.name
          }
        }));
      });
  }
});