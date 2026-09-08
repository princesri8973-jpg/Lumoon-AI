require("dotenv").config();

const express = require("express");
const cors = require("cors");

const chatRoute = require("./routes/chat");

const generateRoute = require("./routes/generate");

const app = express();

// Middlewares
app.use(cors());
app.use(express.json());

// Test Route
app.get("/", (req, res) => {
  res.json({
    success: true,
    message: "🚀 Lumoon AI Backend Running",
  });
});

// Chat API
app.use("/chat", chatRoute);
app.use("/generate", generateRoute);

app.use(
  "/generated",
  express.static(
    require("path").join(__dirname, "generated")
  )
);

// Start Server
const PORT = process.env.PORT || 3000;

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});