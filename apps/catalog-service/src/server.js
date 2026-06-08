const http = require("node:http");

const products = [
  { id: 1, name: "NT548 Lab Notebook", price: 12.5 },
  { id: 2, name: "CloudFormation Starter Kit", price: 24.0 },
  { id: 3, name: "k3s Microservice Bundle", price: 31.5 }
];

function sendJson(res, statusCode, body) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json",
    "Cache-Control": "no-store"
  });
  res.end(JSON.stringify(body));
}

function createServer() {
  return http.createServer((req, res) => {
    const url = new URL(req.url, `http://${req.headers.host || "localhost"}`);

    if (req.method === "GET" && url.pathname === "/health") {
      return sendJson(res, 200, { status: "ok", service: "catalog-service" });
    }

    if (req.method === "GET" && url.pathname === "/api/products") {
      return sendJson(res, 200, { items: products });
    }

    if (req.method === "GET" && url.pathname === "/") {
      return sendJson(res, 200, {
        service: "catalog-service",
        message: "NT548 Lab 2 microservice is running on k3s",
        endpoints: ["/health", "/api/products"]
      });
    }

    return sendJson(res, 404, { error: "not_found" });
  });
}

if (require.main === module) {
  const port = Number(process.env.PORT || 3000);
  createServer().listen(port, "0.0.0.0", () => {
    console.log(`catalog-service listening on port ${port}`);
  });
}

module.exports = { createServer, products };
