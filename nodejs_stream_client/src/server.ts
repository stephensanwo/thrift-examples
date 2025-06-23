import express from "express";
import path from "path";
import thrift from "thrift";
const WeatherMonitorService = require("./generated/WeatherMonitorService");
const {
  WeatherRequest,
  TemperatureReading,
} = require("./generated/weather_types");

const app = express();
const port = 3000;

app.use(express.json());
app.use(express.static(path.join(__dirname, "../public")));

// Thrift client setup
const transport = thrift.TFramedTransport;
const protocol = thrift.TBinaryProtocol;

function createThriftClient(): any {
  const connection = thrift.createConnection("localhost", 9091, {
    transport: transport,
    protocol: protocol,
  });

  connection.on("error", (err: Error) => {
    console.error("Thrift connection error:", err);
  });

  return thrift.createClient(WeatherMonitorService.Client, connection);
}

app.post("/api/temperature", async (req, res) => {
  const { location } = req.body;
  console.log("Received request for location:", location);

  if (!location) {
    return res.status(400).json({ error: "Location is required" });
  }

  try {
    console.log("Creating Thrift client...");
    const client = createThriftClient();
    const request = new WeatherRequest({ location });
    console.log("Created request:", request);

    console.log("Calling Thrift service...");
    const result = await new Promise<any>((resolve, reject) => {
      client.getTemperature(request, (err: Error, response: any) => {
        if (err) {
          console.error("Thrift service error:", err);
          reject(err);
        } else {
          console.log("Received response from Thrift:", response);
          resolve(response);
        }
      });
    });

    // Convert timestamp from Buffer to number if needed
    let timestamp = result.timestamp;
    if (Buffer.isBuffer(timestamp)) {
      timestamp = timestamp.readBigInt64BE();
    } else if (
      timestamp &&
      typeof timestamp === "object" &&
      timestamp.type === "Buffer"
    ) {
      const buf = Buffer.from(timestamp.data);
      timestamp = buf.readBigInt64BE();
    } else {
    }

    const response = {
      temperature: result.temperature,
      location: result.location,
      timestamp: String(timestamp),
      unit: result.unit,
    };

    console.log("Sending response to client:", response);
    res.json(response);
  } catch (error) {
    console.error("Error in /api/temperature:", error);
    res.status(500).json({
      error: "Failed to get temperature data",
      details: error instanceof Error ? error.message : "Unknown error",
    });
  }
});

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "../public/index.html"));
});

app.listen(port, () => {
  console.log(`Weather client server running at http://localhost:${port}`);
  console.log("Make sure the Go Thrift server is running on port 9091");
});
