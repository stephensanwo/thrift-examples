import express from "express";
import path from "path";
import thrift from "thrift";
const LanguageModelService = require("./generated/LanguageModelService");
const {
  TextGenerationRequest,
  TextGenerationResponse,
} = require("./generated/llm_types");

const app = express();
const port = 3005; // Different port from the stream client

app.use(express.json());
app.use(express.static(path.join(__dirname, "../public")));

// Thrift client setup
const transport = thrift.TBufferedTransport;
const protocol = thrift.TBinaryProtocol;

function createThriftClient(): any {
  const connection = thrift.createConnection("localhost", 9090, {
    transport: transport,
    protocol: protocol,
  });

  connection.on("error", (err: Error) => {
    console.error("Thrift connection error:", err);
  });

  connection.on("connect", () => {
    console.log("Connected to Thrift server");
  });

  connection.on("close", () => {
    console.log("Connection to Thrift server closed");
  });

  return thrift.createClient(LanguageModelService.Client, connection);
}

app.post("/api/llm", async (req, res) => {
  const { prompt, temperature, maxTokens } = req.body;
  console.log("Received LLM request:", req.body);

  if (!prompt) {
    return res.status(400).json({ error: "Prompt is required" });
  }

  try {
    console.log("Creating Thrift client...");
    const client = createThriftClient();
    const request = new TextGenerationRequest({
      prompt,
      temperature: temperature || 0.7,
      max_length: maxTokens || 512,
    });
    console.log("Created request:", request);

    console.log("Calling Thrift service...");
    const result = await new Promise<any>((resolve, reject) => {
      client.generateText(request, (err: Error, response: any) => {
        if (err) {
          console.error("Thrift service error:", err);
          reject(err);
        } else {
          console.log("Received response from Thrift:", response);
          resolve(response);
        }
      });
    });

    res.json({
      text: result.generated_text,
      generationTime: result.generation_time,
      inputTokens: result.input_tokens,
      generatedTokens: result.generated_tokens,
    });
  } catch (error) {
    console.error("Error in /api/llm:", error);
    res.status(500).json({
      error: "Failed to generate text",
      details: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});

app.listen(port, () => {
  console.log(`LLM client server running at http://localhost:${port}`);
  console.log("Make sure the Python LLM server is running on port 9090");
});
