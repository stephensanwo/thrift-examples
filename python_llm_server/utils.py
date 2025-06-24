import logging
import time
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def initialize_model():
    """Initialize the TinyLlama model and return necessary components."""
    logger.info("Initializing TinyLlama 1.1B Chat model...")
    
    # Set device to MPS if available, else CPU
    device = 'mps' if torch.backends.mps.is_available() else 'cpu'
    logger.info(f"Using device: {device}")
    
    tokenizer = AutoTokenizer.from_pretrained("TinyLlama/TinyLlama-1.1B-Chat-v1.0")
    
    model = AutoModelForCausalLM.from_pretrained(
        "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
        torch_dtype=torch.float16,
        device_map="auto"
    )
    
    generator = pipeline(
        "text-generation",
        model=model,
        tokenizer=tokenizer,
        torch_dtype=torch.float16
    )
    
    logger.info("Model initialized successfully!")
    return tokenizer, generator

def format_prompt(prompt: str) -> str:
    """Format the input prompt with system and user context."""
    return f"<|system|>\nYou are a helpful AI assistant.\n<|user|>\n{prompt}<|assistant|>"

def generate_text(generator, tokenizer, prompt: str, max_length: int, temperature: float, top_k: int, top_p: float):
    """Generate text using the model with the given parameters."""
    start_time = time.time()
    input_tokens = len(tokenizer.encode(prompt))
    
    formatted_prompt = format_prompt(prompt)
    
    result = generator(
        formatted_prompt,
        max_length=max_length,
        temperature=temperature,
        num_return_sequences=1,
        pad_token_id=tokenizer.eos_token_id,
        do_sample=True,
        top_k=top_k,
        top_p=top_p,
        repetition_penalty=1.1,
        truncation=True 
    )
    
    generation_time = time.time() - start_time
    generated_text = result[0]['generated_text']
    
    response = generated_text.split("<|assistant|>")[-1].strip()
    generated_tokens = len(tokenizer.encode(response))
    
    logger.info(f"Generated text of length {len(response)} ({generated_tokens} tokens) in {generation_time:.2f} seconds")
    
    return response, generation_time, input_tokens, generated_tokens

def classify_text(generator, tokenizer, text: str, labels: list[str]):
    """Classify text into one of the provided labels."""
    start_time = time.time()
    
    # Format prompt for classification
    label_list = ", ".join(labels)
    prompt = f"Classify the following text into one of these categories: {label_list}\n\nText: {text}\n\nCategory:"
    
    result = generator(
        prompt,
        max_length=50,  # Keep short for classification
        temperature=0.1,  # Low temperature for more deterministic output
        num_return_sequences=1,
        pad_token_id=tokenizer.eos_token_id,
        do_sample=True,
        top_k=10,
        top_p=0.95,
        repetition_penalty=1.1,
        truncation=True
    )
    
    # Extract the predicted label
    generated_text = result[0]['generated_text']
    predicted_label = generated_text.split("Category:")[-1].strip()
    
    # Simple confidence score based on exact match
    confidences = {label: 1.0 if label.lower() == predicted_label.lower() else 0.0 for label in labels}
    max_confidence = max(confidences.values())
    
    if max_confidence == 0.0:
        # If no exact match, find the closest label
        predicted_label = min(labels, key=lambda x: abs(len(x) - len(predicted_label)))
        max_confidence = 0.5  # Lower confidence for fuzzy match
    
    classification_time = time.time() - start_time
    
    return predicted_label, max_confidence, classification_time 