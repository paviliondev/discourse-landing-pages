import Controller from "@ember/controller";
import LandingPage from "../models/landing-page";

export default Controller.extend({
  page: {},
  init() {
    const path = window.location.pathname.slice(1);
    LandingPage.all()
      .then((plugin) => plugin.pages.find((page) => page.path == path).id)
      .then((id) => LandingPage.find(id))
      .then((result) => this.set("page", result.page));

    this._super(...arguments);
  }
});
