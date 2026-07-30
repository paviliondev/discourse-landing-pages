import { click, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { acceptance } from "discourse/tests/helpers/qunit-helpers";

acceptance("Main | Navigation", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/admin/plugins/discourse-landing-pages.json", () => {
      return helper.response({ name: "name", description: "description" });
    });
    server.get("/landing/page", () => {
      return helper.response({
        pages: [{ id: "page_0", name: "test", path: "test" }],
      });
    });
  });

  test("Displays only the pages section when selected", async function (assert) {
    await visit("/admin/plugins/discourse-landing-pages/main");
    await click("button.pages");

    assert.dom(".page-list-container").exists();
    assert.dom(".page-global").doesNotExist();
    assert.dom(".d-modal.update-pages-remote").doesNotExist();
    assert.dom(".d-modal.import-pages").doesNotExist();
  });

  test("Displays only the global section when selected", async function (assert) {
    await visit("/admin/plugins/discourse-landing-pages/main");
    await click("button.global");

    assert.dom(".page-list-container").doesNotExist();
    assert.dom(".page-global").exists();
    assert.dom(".d-modal.update-pages-remote").doesNotExist();
    assert.dom(".d-modal.import-pages").doesNotExist();
  });

  test("Displays only the update remote modal over the default section", async function (assert) {
    await visit("/admin/plugins/discourse-landing-pages/main");
    await click("button.remote");

    assert.dom(".page-list-container").exists();
    assert.dom(".page-global").doesNotExist();
    assert.dom(".d-modal.update-pages-remote").exists();
    assert.dom(".d-modal.import-pages").doesNotExist();
  });

  test("Displays only the import pages modal over the default section", async function (assert) {
    await visit("/admin/plugins/discourse-landing-pages/main");
    await click("button.import");

    assert.dom(".page-list-container").exists();
    assert.dom(".page-global").doesNotExist();
    assert.dom(".d-modal.update-pages-remote").doesNotExist();
    assert.dom(".d-modal.import-pages").exists();
  });
});
