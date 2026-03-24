// Simple HTTP server — serves as the example app
const http = require("http");

const PORT = process.env.PORT || 3000;

const server = http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ message: "Hello from Docker!", env: process.env.NODE_ENV }));
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
