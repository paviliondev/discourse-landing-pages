# AGENTS.md

A Discourse plugin that adds server-rendered, admin-authored landing pages to a Discourse forum.

Pages are stored as ERB templates in Discourse's `PluginStore` (not in ActiveRecord tables), rendered
by a Rails controller at the site root (`/:path`), and managed from an Ember admin UI. A page bundle
can be imported from a Git repository or a zip file, or exported as a zip.

## Development environment

This repo is **not runnable on its own**. The specs `require "rails_helper"` and hard-code paths like
`Rails.root/plugins/discourse-landing-pages/spec/fixtures/...`, and the layouts load core helpers
(`ApplicationHelper`, `Email::Styles`, `ThemeStore::*`, `CrawlerDetection`, ...). The plugin must be
checked out at `plugins/discourse-landing-pages` inside a Discourse core checkout.

- Specs (run from the Discourse root, with the plugin loaded):
  `LOAD_PLUGINS=1 bundle exec rspec plugins/discourse-landing-pages/spec`
- Request specs live in `spec/requests/`, model/pipeline specs in `spec/components/`; both
  `require_relative "../plugin_helper"`
- JS acceptance tests (QUnit, run from the Discourse root):
  `bin/rake "plugin:qunit[discourse-landing-pages]"`
- Coverage: set `SIMPLECOV=1` before running specs (`spec/plugin_helper.rb`); note `coverage/` is
  committed to git, so avoid committing incidental coverage churn.

CI (`.github/workflows/discourse-plugin.yml`) only calls the shared
`discourse/.github/.github/workflows/discourse-plugin.yml@v1` workflow with `core_ref: esr`, so
lint + specs run there, not via a local script. Lint tasks below are defined in `package.json` and
use **pnpm** (enforced via `packageManager`/`.npmrc`):

```
pnpm lint            # runs all lint:* (ruby not included)
pnpm lint:js         # eslint on {assets,admin/assets,test}/javascripts
pnpm lint:css        # stylelint on assets/stylesheets/**/*.scss
pnpm lint:prettier   # prettier --check on scss + js/gjs/ts/gts
pnpm lint:types      # ember-tsc -b
pnpm lint:fix        # all of the above with --fix
```

Ruby formatting is `syntax_tree` (`.streerc`: print width 100), not `rubocop -a`; RuboCop inherits
`rubocop-discourse: stree-compat.yml`.

## Architecture

`plugin.rb` is the entry point. It registers assets/routes/admin nav, then `after_initialize`
`require_relative`s **every** Ruby file explicitly. A new file under `lib/`, `app/controllers`,
`app/serializers`, `app/jobs`, `app/mailers`, or `extensions/` will **not** load until it is added to
that list. It also does the cross-cutting wiring: `Site#landing_paths`, `Category#landing_page_id`,
`Topic#landing_page_url`, `TopicView` serializer addition, two `TopicQuery` custom filters
(`definitions_only`, `filter_categories`), and prepends for the extension modules.

Layers:

1. **Persistence** - `PluginStore` rows in namespace `landing_pages`, with keys prefixed by the
   class's `KEY` constant (`page_<hex>`, `menu_<hex>`, `asset_<hex>`, `global`, `remote`).
   Every class exposes `find`, `find_by`, `where`, `all`, `create`, `destroy` itself; queries go
   through raw SQL on `PluginStoreRow` with `value::json->>'attr'` (Postgres JSON operators), and
   list queries filter by `key LIKE 'page_%'`.
2. **Rendering** - `LandingPages::LandingController` (`app/controllers/landing_pages/landing.rb`)
   resolves `@page` by path (or child page via `/:path/:param`), checks `group_ids` access,
   loads `@menu`, `@global`, and each asset in `page.assets` into an instance variable named after
   the asset (`asset "welcome"` becomes `@welcome`, exposing `@welcome.upload.url`), then
   `render inline: @page.body, layout: "landing"`.
   The page body is **ERB evaluated server-side** in the controller context: it can `render partial:
   "contact_form"` / `"subscription_form"` / `"topic_list"`, and call helpers from
   `LandingHelper` (`user_profile`, `user_list`, `topic_list`, `get_topic_view`, `set_parent_page`,
   `set_category_user`) plus `ApplicationHelper`/`EmojiHelper`. See `spec/fixtures/body.html.erb`
   for a representative page body. Styles are a flat SCSS stack in `assets/stylesheets/page/`
   compiled into the `landing_page` stylesheet (registered in `plugin.rb` via
   `Stylesheet::Importer.plugin_assets`), so pages do **not** inherit the forum theme unless a
   `theme_id` is set.
3. **Serving/redirects** - routes are `prepend`ed onto `Discourse::Application.routes`: a catch-all
   `get "/:path"` guarded by `LandingPageConstraint` (a `PluginStore` lookup on every request) plus
   the engine mounted at `/landing` for forms, topic-list pagination, and admin JSON endpoints.
   `SiteSetting.landing_redirect_to_homepages` diverts to a Home Pages theme component path unless
   the request is from a crawler (`visit_from_crawler?` preserves SEO).
4. **Admin API** - `LandingPages::AdminController` subclasses (`Page`, `Global`, `Remote`) use
   `requires_plugin` and respond with `ActiveModel::Serializer`s from `app/serializers/landing_pages/`.
5. **Import/export** - `LandingPages::Importer` (`:git` or `:zip`) builds a `GitImporter`/`ZipImporter`
   (both subclass `ThemeStore::*`), then `LandingPages::Updater` maps bundle files to models:
   `page.json` + sibling `body.html.erb` per page, `pages.json` (global scripts/header/footer + menus),
   and `assets.json` (`{"register": {"name": "file.json"}}`). `Importer#perform!` =
   `import!` -> `update!` -> `cleanup!`, accumulating a `report` of `{ imported:, errors: [] }`.
   `Updater#updated` is keyed `scripts/footer/header/menus/assets/pages` and drives the admin flash
   messages, so keep those keys in sync with `config/locales/client.*.yml`.
6. **Admin UI** - Ember Octane components in `admin/assets/javascripts/discourse/` (moved out of the
   regular `assets` bundle in commit `545d48e`); route map points at
   `adminPlugins.show.discourse-landing-pages` (`/admin/plugins/discourse-landing-pages/main`),
   registered through `api.addAdminPluginConfigurationNav`. `models/landing-page.js` is a plain
   `EmberObject` with `ajax()` calls to `/landing/page`. The JSON editors wrap core
   `discourse/components/ace-editor` and point Ace at `public/javascripts/ace` (vendored), which is
   why `plugin.rb` extends the CSP with `https://ajax.googleapis.com` and why global `scripts` are
   injected into `script_src`.
7. **Forum integration** - `extensions/*.rb` are prepended onto core classes: upload validation
   allows `SiteSetting.landing_authorized_extensions` for landing-page uploads, uploads get a
   `for_landing_page` flag, and `UserNotifications` replaces the notification email HTML for the
   first post in a category that has a landing page (`LandingEmailRenderer` + `email/landing.html.erb`).

## Conventions

- Everything is namespaced `LandingPages::`; a store-backed model is a plain Ruby class including
  `HasErrors` and `ActiveModel::Serialization`, with `self.writable_attrs` driving both `#set` and
  `#save` (so adding an attribute means adding it to `writable_attrs`, the serializer, the controller
  `permit` list, the JS model, and locales).
- Attributes are normalized in `#set`: `path` is `dasherize`d, `name` is `parameterize.underscore`
  (menus/assets), `category_id`/`theme_id` are cast to int, `group_ids` to an int array.
  Page ids/paths are validated in `#validate` against `required_attrs` and against
  `application_paths` (top-level Discourse routes) to avoid shadowing core routes.
- `Page.find_discourse_objects` translates human-readable `theme`/`groups`/`category` names (or ids)
  from import bundles into `theme_id`/`group_ids`/`category_id`; unknown objects are silently dropped.
- Serializers subclass `::ApplicationSerializer` and are used with `root: false`.
- All user-facing text goes through I18n: server keys under `landing_pages.*`, client keys under
  `js.admin_js.admin.landing_pages.*`. There are four locales (`en`, `es`, `gl`, `pt`) and all four
  are maintained - add keys to every one.
- Front-end code outside the admin bundle is plain jQuery in `public/javascripts/` (`common.js`,
  `desktop.js`, `mobile.js`) loaded directly by `app/views/layouts/landing.html.erb`; it handles the
  contact/subscription form AJAX and infinite-scroll topic lists.
- Server-side errors: models accumulate errors and return `false` from `save`; controllers translate
  that into `render_json_error`. Custom exceptions are `LandingPages::InvalidAccess` (403 via
  `rescue_from`) and `LandingPages::InvalidParameters`.
- There is no database migration path: `PluginStore` is schemaless, so schema changes are code-only
  (but existing rows are not migrated - handle missing/legacy attributes defensively).

## Gotchas

- **Add new Ruby files to the `require_relative` list in `plugin.rb`** or they are never loaded.
- `LandingPages::Cache` (`Discourse.cache`, keys `discourse-landing-pages_paths` /
  `discourse-landing-pages_category_ids`) caches page paths and the category -> page map. `Page#save`
  only rebuilds the category map, and nothing invalidates `PATHS_KEY` on create/destroy, so after
  adding/removing pages the client-side `site.landing_paths` (used by
  `assets/javascripts/discourse/initializers/landing-pages-edits.js` to force full page loads) can be
  stale until the cache expires. Use `LandingPages::Cache#delete` when you need correctness.
- SQL is hand-built. `Page.page_query`, `Menu.menu_query` and `Asset.query` interpolate the attribute
  name/value into the string; `Page` uses `?` binding for values but `Menu`/`Asset` interpolate the
  value directly. Prefer the `Page` style when adding query methods.
- The `/:path` catch-all is prepended to Discourse routes. Adding a top-level page path that collides
  with a core route is blocked by `Page.path_exists?`, but new core routes can be shadowed - be
  careful with generic paths.
- Page bodies are trusted ERB: changing rendering means changing what admins can execute server-side.
- `Group::AUTO_GROUPS[:everyone]` in `group_ids` means public; an empty/nil `group_ids` also means
  public. Changing this check changes access control for every page.
- `spec/fixtures/remote.json` contains a real (old) SSH key pair; do not use it or add similar
  fixtures.
- Ruby specs stub git/zip import heavily (`LandingPages::GitImporter.any_instance.stubs(...)` with
  mocha) and point `temp_folder` at `spec/fixtures`; keep new importer logic compatible with a
  filesystem-backed handler so tests stay offline.
- Terminology drift to watch for: `Global` == the `global` store row holding `scripts`/`header`/`footer`;
  `Remote` == the single Git repo config; menus are stored separately but referenced by `page.menu`
  name and rendered as `@menu` in the layout, so header/footer/menu partials depend on that ivar.
- `Page` writes `value::json->>'attr'` comparisons; when adding an attribute used for lookups, it must
  be present in the stored JSON via `writable_attrs`, or queries return nothing.
- The version in the `plugin.rb` header and the pins in `.discourse-compatibility` are what CI
  compatibility checks read; update both when claiming a new Discourse compatibility range.
