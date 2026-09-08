const express = require("express");
const fs = require("fs");
const os = require("os");
const path = require("path");
const multer = require("multer");
const {
  GoogleGenAI,
  createUserContent,
  createPartFromUri,
} = require("@google/genai");

const router = express.Router();

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

const uploadFolder = path.join(os.tmpdir(), "lumoon-uploads");

if (!fs.existsSync(uploadFolder)) {
  fs.mkdirSync(uploadFolder, { recursive: true });
}

const upload = multer({
  dest: uploadFolder,
  limits: {
    fileSize: 20 * 1024 * 1024, // 20 MB
  },
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
- Use easy Tanglish.
- Do not force Tanglish into code, commands, filenames, or technical syntax.

Answer style:
- Start with the direct answer.
- Keep normal answers concise.
- Use bullets when they make the answer easier to understand.
- For coding help, explain what to do first, then give the code.
`;

router.post(
  "/",
  (req, res, next) => {
    upload.single("file")(req, res, (error) => {
      if (error) {
        const message =
          error.code === "LIMIT_FILE_SIZE"
            ? "File size 20 MB-kulla irukkanum."
            : error.message || "File upload error.";

        return res.status(400).json({
          success: false,
          error: message,
        });
      }

      next();
    });
  },
  async (req, res) => {
    try {
      const typedPrompt = req.body?.prompt?.trim() || "";
      const file = req.file;

      if (!typedPrompt && !file) {
        return res.status(400).json({
          success: false,
          error: "Question or file is required.",
        });
      }

      const prompt =
        typedPrompt ||
        "Indha file-a simple Tanglish-la explain pannu. Important points-um kudu.";

      console.log("User:", prompt);

      let contents = prompt;

      if (file) {
        console.log("Attached file:", file.originalname);

        const uploadedFile = await ai.files.upload({
          file: file.path,
          config: {
            mimeType: file.mimetype,
            displayName: file.originalname,
          },
        });

        contents = createUserContent([
          createPartFromUri(uploadedFile.uri, uploadedFile.mimeType),
          prompt,
        ]);
      }

      const result = await ai.models.generateContent({
        model: "gemini-3.6-flash",
        contents: contents,
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
    } finally {
      if (req.file?.path) {
        fs.promises.unlink(req.file.path).catch(() => {});
      }
    }
  }
);

module.exports = router;