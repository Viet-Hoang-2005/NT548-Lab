const assert = require("node:assert/strict");
const { test } = require("node:test");
const { createServer } = require("../src/server");

function startTestServer() {
  const server = createServer();
  return new Promise((resolve) => {
    server.listen(0, "127.0.0.1", () => {
      const { port } = server.address();
      resolve({ server, baseUrl: `http://127.0.0.1:${port}` });
    });
  });
}

test("GET /health returns service health", async () => {
  const { server, baseUrl } = await startTestServer();
  try {
    const response = await fetch(`${baseUrl}/health`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.equal(body.status, "ok");
    assert.equal(body.service, "catalog-service");
  } finally {
    server.close();
  }
});

test("GET /api/products returns product list", async () => {
  const { server, baseUrl } = await startTestServer();
  try {
    const response = await fetch(`${baseUrl}/api/products`);
    const body = await response.json();

    assert.equal(response.status, 200);
    assert.ok(Array.isArray(body.items));
    assert.equal(body.items.length, 3);
  } finally {
    server.close();
  }
});

test("unknown route returns 404", async () => {
  const { server, baseUrl } = await startTestServer();
  try {
    const response = await fetch(`${baseUrl}/missing`);
    const body = await response.json();

    assert.equal(response.status, 404);
    assert.equal(body.error, "not_found");
  } finally {
    server.close();
  }
});
