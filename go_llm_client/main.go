package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/apache/thrift/lib/go/thrift"

	"go_llm_client/llm"
)

func main() {
	conf := &thrift.TConfiguration{
		ConnectTimeout: 30 * time.Second,
		SocketTimeout:  30 * time.Second,
	}
	
	transport := thrift.NewTSocketConf("localhost:9090", conf)
	defer transport.Close()

	protocolFactory := thrift.NewTBinaryProtocolFactoryConf(conf)
	protocol := protocolFactory.GetProtocol(transport)
	
	client := llm.NewLanguageModelServiceClient(thrift.NewTStandardClient(protocol, protocol))

	if err := transport.Open(); err != nil {
		log.Fatal("Error opening transport:", err)
	}

	ctx := context.Background()

	generateRequest := &llm.TextGenerationRequest{
		Prompt:      "Once upon a time in Silicon Valley,",
		MaxLength:   150,
		Temperature: 0.8,
	}

	fmt.Printf("\nGenerating text with prompt: %s\n", generateRequest.Prompt)
	genResult, err := client.GenerateText(ctx, generateRequest)
	if err != nil {
		log.Fatal("Error calling GenerateText:", err)
	}
	fmt.Printf("\nGenerated Text (took %.2f seconds):\n%s\n\n",
		genResult.GenerationTime,
		genResult.GeneratedText)

	classifyRequest := &llm.TextClassificationRequest{
		Text: "I absolutely loved this movie! The acting was superb and the story was engaging.",
		Labels: []string{
			"positive",
			"negative",
			"neutral",
		},
	}

	fmt.Printf("Classifying text: %s\n", classifyRequest.Text)
	classResult, err := client.ClassifyText(ctx, classifyRequest)
	if err != nil {
		log.Fatal("Error calling ClassifyText:", err)
	}
	fmt.Printf("\nClassification Result (took %.2f seconds):\nLabel: %s\nConfidence: %.2f\n",
		classResult.ClassificationTime,
		classResult.Label,
		classResult.Confidence)

	techClassifyRequest := &llm.TextClassificationRequest{
		Text: "Python is a versatile programming language with great libraries for machine learning and data science.",
		Labels: []string{
			"technology",
			"sports",
			"entertainment",
			"education",
		},
	}

	fmt.Printf("\nClassifying text: %s\n", techClassifyRequest.Text)
	techClassResult, err := client.ClassifyText(ctx, techClassifyRequest)
	if err != nil {
		log.Fatal("Error calling ClassifyText:", err)
	}
	fmt.Printf("\nClassification Result (took %.2f seconds):\nLabel: %s\nConfidence: %.2f\n",
		techClassResult.ClassificationTime,
		techClassResult.Label,
		techClassResult.Confidence)
}