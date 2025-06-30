import express from "express";
import path from "path";
import thrift from "thrift";
const LanguageModelService = require("./generated/LanguageModelService");
const {
  TextGenerationRequest,
  TextGenerationResponse,
} = require("./generated/llm_types");

const app = express();
const port = 3005;

app.use(express.json());
app.use(express.static(path.join(__dirname, "../public")));

// Thrift client setup
const transport = thrift.TBufferedTransport;
const protocol = thrift.TBinaryProtocol;

let thriftClient: any = null;
let thriftConnection: any = null;

function createThriftClient(): any {
  if (thriftClient && thriftConnection && thriftConnection.connected) {
    return thriftClient;
  }

  // Close existing connection if any
  if (thriftConnection) {
    try {
      thriftConnection.end();
    } catch (error) {
      console.log("Error closing existing connection:", error);
    }
  }

  thriftConnection = thrift.createConnection("localhost", 9090, {
    transport: transport,
    protocol: protocol,
    timeout: 30000, // 30 seconds timeout
    max_attempts: 3,
    retry_max_delay: 2000,
  });

  thriftConnection.on("error", (err: Error) => {
    console.error("Thrift connection error:", err);
    thriftClient = null;
  });

  thriftConnection.on("connect", () => {
    console.log("Connected to Thrift server");
  });

  thriftConnection.on("close", () => {
    console.log("Connection to Thrift server closed");
    thriftClient = null;
  });

  thriftClient = thrift.createClient(
    LanguageModelService.Client,
    thriftConnection
  );
  return thriftClient;
}

app.post("/api/llm", async (req, res) => {
  const { prompt, temperature, maxTokens } = req.body;
  console.log("Received LLM request:", req.body);

  if (!prompt) {
    return res.status(400).json({ error: "Prompt is required" });
  }

  try {
    console.log("Getting Thrift client...");
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
          // Reset client on error to force reconnection on next request
          thriftClient = null;
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

// Cleanup connection on server shutdown
process.on("SIGTERM", () => {
  console.log("Received SIGTERM. Closing Thrift connection...");
  if (thriftConnection) {
    thriftConnection.end();
  }
  process.exit(0);
});

process.on("SIGINT", () => {
  console.log("Received SIGINT. Closing Thrift connection...");
  if (thriftConnection) {
    thriftConnection.end();
  }
  process.exit(0);
});

app.listen(port, () => {
  console.log(`LLM client server running at http://localhost:${port}`);
  console.log("Make sure the Python LLM server is running on port 9090");
});
