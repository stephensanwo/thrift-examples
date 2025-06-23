import sys
import os
import time
import logging
import torch
from transformers import AutoModelForCausalLM, AutoTokenizer, pipeline
from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
from thrift.server import TServer

sys.path.append(os.path.join(os.path.dirname(__file__), '../generated/python'))

from llm import LanguageModelService
from llm.ttypes import (
    TextGenerationRequest,
    TextGenerationResponse,
    TextClassificationRequest,
    TextClassificationResponse,
    ModelError
)

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class LanguageModelHandler:
    def __init__(self):
        logger.info("Initializing TinyLlama 1.1B Chat model...")
        
        # Set device to MPS if available, else CPU
        self.device = 'mps' if torch.backends.mps.is_available() else 'cpu'
        logger.info(f"Using device: {self.device}")
        
        self.tokenizer = AutoTokenizer.from_pretrained("TinyLlama/TinyLlama-1.1B-Chat-v1.0")
        
        self.model = AutoModelForCausalLM.from_pretrained(
            "TinyLlama/TinyLlama-1.1B-Chat-v1.0",
            torch_dtype=torch.float16,
            device_map="auto"
        )
        
        self.generator = pipeline(
            "text-generation",
            model=self.model,
            tokenizer=self.tokenizer,
            torch_dtype=torch.float16
        )
        
        logger.info("Model initialized successfully!")

    def generateText(self, request):
        try:
            logger.info(f"Received generation request with prompt: {request.prompt[:50]}...")
            start_time = time.time()
            
            input_tokens = len(self.tokenizer.encode(request.prompt))
            

            formatted_prompt = f"<|system|>\nYou are a helpful AI assistant.\n<|user|>\n{request.prompt}<|assistant|>"
            
            result = self.generator(
                formatted_prompt,
                max_length=request.max_length,
                temperature=request.temperature,
                num_return_sequences=1,
                pad_token_id=self.tokenizer.eos_token_id,
                do_sample=True,
                top_k=request.top_k,
                top_p=request.top_p,
                repetition_penalty=1.1,
                truncation=True 
            )
            
            generation_time = time.time() - start_time
            generated_text = result[0]['generated_text']
            
            response = generated_text.split("<|assistant|>")[-1].strip()
            generated_tokens = len(self.tokenizer.encode(response))
            
            logger.info(f"Generated text of length {len(response)} ({generated_tokens} tokens) in {generation_time:.2f} seconds")
            return TextGenerationResponse(
                generated_text=response,
                generation_time=generation_time,
                input_tokens=input_tokens,
                generated_tokens=generated_tokens
            )
            
        except Exception as e:
            logger.error(f"Error in text generation: {str(e)}")
            raise ModelError(
                message="Failed to generate text",
                details=str(e)
            )

    def classifyText(self, request):
        try:
            logger.info(f"Received classification request for text: {request.text[:50]}...")
            start_time = time.time()
            
            labels_str = ", ".join(f"'{label}'" for label in request.labels)
            formatted_prompt = f"<|system|>\nYou are a text classification assistant. Classify the following text into exactly one of these categories: {labels_str}. Respond with ONLY the category name, nothing else.\n<|user|>\nText to classify: {request.text}\n<|assistant|>"
            

            result = self.generator(
                formatted_prompt,
                max_length=len(formatted_prompt) + 50,
                temperature=0.1,
                num_return_sequences=1,
                pad_token_id=self.tokenizer.eos_token_id,
                do_sample=False,
                truncation=True
            )
            
            classification_time = time.time() - start_time
            
            response = result[0]['generated_text'].split("<|assistant|>")[-1].strip()
            
            predicted_label = None
            max_confidence = 0.0
            
            response = response.strip("'\" ")
            
            for label in request.labels:
                if label.lower() == response.lower():
                    predicted_label = label
                    max_confidence = 0.95
                    break
            
            if predicted_label is None:
                for label in request.labels:
                    if label.lower() in response.lower():
                        predicted_label = label
                        max_confidence = 0.7
                        break
            
            if predicted_label is None:
                predicted_label = request.labels[0]
                max_confidence = 0.3
                logger.warning(f"Could not match model response '{response}' to any label, using default")
            
            logger.info(f"Classified text as '{predicted_label}' with confidence {max_confidence:.2f} in {classification_time:.2f} seconds")
            return TextClassificationResponse(
                label=predicted_label,
                confidence=max_confidence,
                classification_time=classification_time
            )
            
        except Exception as e:
            logger.error(f"Error in text classification: {str(e)}")
            raise ModelError(
                message="Failed to classify text",
                details=str(e)
            )


def main():
    handler = LanguageModelHandler()
    processor = LanguageModelService.Processor(handler)
    transport = TSocket.TServerSocket(host='localhost', port=9090)
    tfactory = TTransport.TBufferedTransportFactory()
    pfactory = TBinaryProtocol.TBinaryProtocolFactory()
    
    server = TServer.TSimpleServer(processor, transport, tfactory, pfactory)
    
    logger.info("Starting Language Model server on port 9090...")
    server.serve()


if __name__ == "__main__":
    main() 