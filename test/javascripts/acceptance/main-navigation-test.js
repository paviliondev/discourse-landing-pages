import { acceptance, exists } from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import { click, visit } from "@ember/test-helpers";

acceptance("Main | Navigation", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/landing/page", () => {
      return helper.response({
        pages: [{ id: "page_0", name: "test", path: "test" }],
      });
    });
  });

  test("Displays only the pages section when selected", async function (assert) {
    await visit("/admin/plugins/landing-pages");
    await click("button.pages");

    assert.ok(exists(".page-list-container"));
    assert.notOk(exists(".page-global"));
    assert.notOk(exists(".d-modal.update-pages-remote"));
    assert.notOk(exists(".d-modal.import-pages"));
  });

  test("Displays only the global section when selected", async function (assert) {
    await visit("/admin/plugins/landing-pages");
    await click("button.global");

    assert.notOk(exists(".page-list-container"));
    assert.ok(exists(".page-global"));
    assert.notOk(exists(".d-modal.update-pages-remote"));
    assert.notOk(exists(".d-modal.import-pages"));
  });

  test("Displays only the update remote modal over the default section", async function (assert) {
    await visit("/admin/plugins/landing-pages");
    await click("button.remote");

    assert.ok(exists(".page-list-container"));
    assert.notOk(exists(".page-global"));
    assert.ok(exists(".d-modal.update-pages-remote"));
    assert.notOk(exists(".d-modal.import-pages"));
  });

  test("Displays only the import pages modal over the default section", async function (assert) {
    await visit("/admin/plugins/landing-pages");
    await click("button.import");

    assert.ok(exists(".page-list-container"));
    assert.notOk(exists(".page-global"));
    assert.notOk(exists(".d-modal.update-pages-remote"));
    assert.ok(exists(".d-modal.import-pages"));
  });
});
