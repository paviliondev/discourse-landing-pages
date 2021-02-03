import DiscourseURL from 'discourse/lib/url';

export default {
  name: 'landing-pages-edits',
  initialize(container) {
    const site = container.lookup('site:main');
    const existing = DiscourseURL.routeTo;
            
    DiscourseURL.routeTo = function(url, opts) {
      let parser = document.createElement('a');
      parser.href = url;
      if (parser.pathname && site.landing_paths.includes(parser.pathname.replace(/^\//, ''))) {
        return window.location = url;
      }
      return existing.apply(this, [url, opts]);
    };
  }
};
