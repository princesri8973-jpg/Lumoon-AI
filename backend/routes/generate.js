const express = require("express");
const fs = require("fs");
const path = require("path");

const {
  Document,
  Packer,
  Paragraph,
  HeadingLevel,
} = require("docx");

const ExcelJS = require("exceljs");
const PptxGenJS = require("pptxgenjs");

const { GoogleGenAI } = require("@google/genai");

const router = express.Router();

const ai = new GoogleGenAI({
  apiKey: process.env.GEMINI_API_KEY,
});

const outputFolder = path.join(__dirname, "..", "generated");

if (!fs.existsSync(outputFolder)) {
  fs.mkdirSync(outputFolder, { recursive: true });
}

function safeName(text) {
  return (
    text
      .replace(/[^a-zA-Z0-9_-]/g, "_")
      .substring(0, 40) || "lumoon_file"
  );
}

async function generateText(prompt) {
  const result = await ai.models.generateContent({
    model: "gemini-3.6-flash",
    contents: prompt,
    config: {
      systemInstruction: `
You are Lumoon, a helpful AI assistant.
Generate useful, clean and well-organized content.
Do not add unnecessary explanations.
`,
    },
  });

  return result.text || "";
}

/* ---------------- WORD ---------------- */

router.post("/word", async (req, res) => {
  try {
    const prompt = req.body?.prompt?.trim();

    if (!prompt) {
      return res.status(400).json({
        success: false,
        error: "Word content prompt required.",
      });
    }

    const content = await generateText(`
Create a professional Word document based on this request:

${prompt}

Return only the document content.
Use clear headings and paragraphs.
`);

    const lines = content
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean);

    const children = [];

    for (const line of lines) {
      if (
        line.startsWith("# ") ||
        line.startsWith("## ") ||
        line.endsWith(":")
      ) {
        children.push(
          new Paragraph({
            text: line.replace(/^#+\s*/, ""),
            heading: HeadingLevel.HEADING_2,
          })
        );
      } else {
        children.push(
          new Paragraph({
            text: line,
          })
        );
      }
    }

    const document = new Document({
      sections: [
        {
          properties: {},
          children,
        },
      ],
    });

    const buffer = await Packer.toBuffer(document);

    const filename = `${safeName(prompt)}_${Date.now()}.docx`;
    const filepath = path.join(outputFolder, filename);

    fs.writeFileSync(filepath, buffer);

    res.json({
      success: true,
      type: "word",
      filename,
      url: `/generated/${filename}`,
    });
  } catch (error) {
    console.error("WORD ERROR:", error);

    res.status(500).json({
      success: false,
      error: error.message || "Word creation failed.",
    });
  }
});

/* ---------------- EXCEL ---------------- */

router.post("/excel", async (req, res) => {
  try {
    const prompt = req.body?.prompt?.trim();

    if (!prompt) {
      return res.status(400).json({
        success: false,
        error: "Excel prompt required.",
      });
    }

    const content = await generateText(`
Create spreadsheet data for this request:

${prompt}

Return ONLY TSV data.
First line must contain column headers.
Each next line must contain one row.
Separate columns using TAB.
Do not use markdown.
`);

    const workbook = new ExcelJS.Workbook();
    const sheet = workbook.addWorksheet("Lumoon");

    const rows = content
      .split("\n")
      .map((line) => line.trim())
      .filter(Boolean)
      .map((line) => line.split("\t"));

    for (const row of rows) {
      sheet.addRow(row);
    }

    sheet.columns.forEach((column) => {
      column.width = 22;
    });

    if (sheet.rowCount > 0) {
      const header = sheet.getRow(1);

      header.font = {
        bold: true,
      };

      header.alignment = {
        vertical: "middle",
        horizontal: "center",
      };
    }

    const filename = `${safeName(prompt)}_${Date.now()}.xlsx`;
    const filepath = path.join(outputFolder, filename);

    await workbook.xlsx.writeFile(filepath);

    res.json({
      success: true,
      type: "excel",
      filename,
      url: `/generated/${filename}`,
    });
  } catch (error) {
    console.error("EXCEL ERROR:", error);

    res.status(500).json({
      success: false,
      error: error.message || "Excel creation failed.",
    });
  }
});

/* ---------------- POWERPOINT ---------------- */

router.post("/powerpoint", async (req, res) => {
  try {
    const prompt = req.body?.prompt?.trim();

    if (!prompt) {
      return res.status(400).json({
        success: false,
        error: "PowerPoint prompt required.",
      });
    }

    const content = await generateText(`
Create a PowerPoint presentation outline for:

${prompt}

Use exactly this format:

SLIDE: Title
- Bullet point
- Bullet point
- Bullet point

Create around 6 to 10 slides.
Do not use markdown headings other than SLIDE:.
`);

    const pptx = new PptxGenJS();

    pptx.layout = "LAYOUT_WIDE";
    pptx.author = "Lumoon AI";
    pptx.subject = prompt;
    pptx.title = prompt;

    const blocks = content.split(/SLIDE:/i).filter(Boolean);

    for (const block of blocks) {
      const lines = block
        .split("\n")
        .map((line) => line.trim())
        .filter(Boolean);

      if (lines.length === 0) continue;

      const title = lines[0];

      const slide = pptx.addSlide();

      slide.background = {
        color: "0B0F19",
      };

      slide.addText(title, {
        x: 0.6,
        y: 0.5,
        w: 12,
        h: 0.7,
        fontSize: 28,
        bold: true,
        color: "00E5FF",
      });

      const bullets = lines
        .slice(1)
        .map((line) => ({
          text: line.replace(/^[-*]\s*/, ""),
          options: {
            bullet: {
              indent: 18,
            },
          },
        }));

      slide.addText(bullets, {
        x: 0.9,
        y: 1.5,
        w: 11.5,
        h: 5,
        fontSize: 20,
        color: "FFFFFF",
        breakLine: true,
        valign: "top",
      });
    }

    const filename = `${safeName(prompt)}_${Date.now()}.pptx`;
    const filepath = path.join(outputFolder, filename);

    await pptx.writeFile({
      fileName: filepath,
    });

    res.json({
      success: true,
      type: "powerpoint",
      filename,
      url: `/generated/${filename}`,
    });
  } catch (error) {
    console.error("POWERPOINT ERROR:", error);

    res.status(500).json({
      success: false,
      error: error.message || "PowerPoint creation failed.",
    });
  }
});

/* ---------------- IMAGE ---------------- */

router.post("/image", async (req, res) => {
  try {
    const prompt = req.body?.prompt?.trim();

    if (!prompt) {
      return res.status(400).json({
        success: false,
        error: "Image prompt required.",
      });
    }

    const response = await ai.models.generateContent({
      model: "gemini-3.1-flash-image",
      contents: prompt,
      config: {
        responseModalities: ["IMAGE"],
      },
    });

    const parts =
      response?.candidates?.[0]?.content?.parts || [];

    const imagePart = parts.find(
      (part) => part.inlineData?.data
    );

    if (!imagePart) {
      throw new Error("Image generation returned no image.");
    }

    const imageBuffer = Buffer.from(
      imagePart.inlineData.data,
      "base64"
    );

    const filename = `${safeName(prompt)}_${Date.now()}.png`;
    const filepath = path.join(outputFolder, filename);

    fs.writeFileSync(filepath, imageBuffer);

    res.json({
      success: true,
      type: "image",
      filename,
      url: `/generated/${filename}`,
    });
  } catch (error) {
    console.error("IMAGE ERROR:", error);

    res.status(500).json({
      success: false,
      error: error.message || "Image creation failed.",
    });
  }
});

module.exports = router;