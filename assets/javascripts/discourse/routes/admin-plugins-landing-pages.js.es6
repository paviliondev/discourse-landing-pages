import LandingPage from '../models/landing-page';
import { ajax } from 'discourse/lib/ajax';
import DiscourseRoute from "discourse/routes/discourse";
import Group from "discourse/models/group";
import { set } from "@ember/object";
import { all } from "rsvp";

export default DiscourseRoute.extend({
  model(params) {
    return LandingPage.all();
  },
  
  afterModel(model) {
    return all([
      this._getThemes(model),
      this._getGroups(model)
    ]);
  },

  setupController(controller, model) {
    controller.setProperties({
      pages: model.pages,
      themes: model.themes,
      groups: model.groups
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
  },
  
  _getGroups(model) {
    return Group.findAll().then(groups => {
      set(model, 'groups', groups);
    });
  }
});