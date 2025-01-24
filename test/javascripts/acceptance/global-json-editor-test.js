import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import { test } from "qunit";
import {
  click,
  fillIn,
  triggerEvent,
  visit,
  waitFor,
} from "@ember/test-helpers";

acceptance("Global | JSON editor", function (needs) {
  needs.user();
  needs.pretender((server, helper) => {
    server.get("/landing/page", () => {
      return helper.response({
        pages: [{ id: "page_0", name: "test", path: "test" }],
      });
    });
  });

  test("Loads an instance of the Ace editor", async function (assert) {
    await visit("/admin/plugins/landing-pages");
    await click("button.global");

    assert.ok(exists(".ace_editor"));
  });

  test("Highlights a JSON syntax error", async function (assert) {
    const invalidJson = "invalidjson";

    await visit("/admin/plugins/landing-pages");
    await click("button.global");
    await fillIn("textarea.ace_text-input", invalidJson);
    await waitFor(".ace_gutter-layer .ace_error");
    await triggerEvent(".ace_gutter-layer .ace_error", "mousemove");
    await waitFor(".ace_tooltip");

    assert.ok(query(".ace_tooltip").innerText.trim() === "Unexpected 'i'");
  });

  test("Wraps a long line of JSON code", async function (assert) {
    const longJson =
      '{"valid_and_long_json_key":"This is a valid and long JSON value that will make the selected editor to either wrap it in multiple lines if properly configured, or to overflow and display the horizontal scrollbar."}';

    await visit("/admin/plugins/landing-pages");
    await click("button.global");
    await fillIn("textarea.ace_text-input", longJson);

    assert.ok(query(".ace_scrollbar-h").style["display"] === "none");
  });
});
