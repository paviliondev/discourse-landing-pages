import DiscourseRoute from 'discourse/routes/discourse';
import LandingPage from "../models/landing-page";

export default DiscourseRoute.extend({
  model(params) {
    return LandingPage.all()
      .then((result) => result.pages.find((page) => page.path == params.path))
      .then((page) => LandingPage.find(page.id));
  }
});
