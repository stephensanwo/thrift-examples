namespace go llm
namespace py llm

struct TextGenerationRequest {
    1: string prompt
    2: i32 max_length = 512
    3: double temperature = 0.7
    4: double top_p = 0.95
    5: i32 top_k = 50
}

struct TextGenerationResponse {
    1: string generated_text
    2: double generation_time
    3: i32 input_tokens
    4: i32 generated_tokens
}

struct TextClassificationRequest {
    1: string text
    2: list<string> labels
}

struct TextClassificationResponse {
    1: string label
    2: double confidence
    3: double classification_time
}

exception ModelError {
    1: string message
    2: string details
}

service LanguageModelService {
    TextGenerationResponse generateText(1: TextGenerationRequest request) throws (1: ModelError error)
    TextClassificationResponse classifyText(1: TextClassificationRequest request) throws (1: ModelError error)
} 