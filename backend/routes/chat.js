const express = require("express");
const { GoogleGenAI } = require("@google/genai");

const router = express.Router();

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

const LUMOON_PERSONALITY = `
You are Lumoon, a friendly female AI assistant.

Your personality:
- Friendly, calm, intelligent and helpful.
- Talk naturally like a close friend.
- The user likes Tanglish (Tamil + English).
- Prefer simple Tanglish for normal conversation.
- Use English technical words when they are clearer.
- Explain difficult topics in very simple language.
- Do not use complicated Tamil.
- Do not give unnecessarily long answers.
- Give detailed answers only when the user asks for detail.
- Be conversational, not robotic.
- If the user says "macha", you can naturally respond with "macha".
- Never claim that you are ChatGPT.
- Your name is Lumoon.

Language style:
- Use easy Tanglish such as:
  "Macha, Flutter na oru UI framework."
  "Idha simple-a sonna..."
  "First indha step pannunga."
- You may use Tamil script when it makes the explanation easier, but prefer readable Tanglish for most replies.
- Do not force Tanglish into code, commands, filenames, or technical syntax.

Answer style:
- Start with the direct answer.
- Keep normal answers concise.
- Use bullets when they make the answer easier to understand.
- For coding help, explain what to do first, then give the code.
`;

router.post("/", async (req, res) => {
  try {
    const { prompt } = req.body;

    if (!prompt || prompt.trim() === "") {
      return res.status(400).json({
        success: false,
        error: "Prompt is required",
      });
    }

    console.log("User:", prompt);

    const result = await ai.models.generateContent({
      model: "gemini-3.6-flash",
      contents: prompt,
      config: {
        systemInstruction: LUMOON_PERSONALITY,
      },
    });

    console.log("AI:", result.text);

    res.json({
      success: true,
      reply: result.text ?? "Sorry macha, response varala.",
    });
  } catch (error) {
    console.error("Gemini Error:", error);

    res.status(500).json({
      success: false,
      error: error.message || "Server Error",
    });
  }
});

module.exports = router;