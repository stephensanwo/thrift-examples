import sys
import os
import logging
from thrift.transport import TSocket
from thrift.transport import TTransport
from thrift.protocol import TBinaryProtocol
from thrift.server import TServer

sys.path.append(os.path.join(os.path.dirname(__file__), '../generated/python'))
sys.path.append(os.path.dirname(__file__))

from llm import LanguageModelService
from llm.ttypes import (
    TextGenerationRequest,
    TextGenerationResponse,
    TextClassificationRequest,
    TextClassificationResponse,
    ModelError
)
from utils import (
    initialize_model,
    generate_text,
    classify_text,
    logger
)

class LanguageModelHandler:
    def __init__(self):
        self.tokenizer, self.generator = initialize_model()

    def generateText(self, request):
        try:
            logger.info(f"Received generation request with prompt: {request.prompt[:50]}...")
            
            response, generation_time, input_tokens, generated_tokens = generate_text(
                self.generator,
                self.tokenizer,
                request.prompt,
                request.max_length,
                request.temperature,
                request.top_k,
                request.top_p
            )
            
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
            
            predicted_label, max_confidence, classification_time = classify_text(
                self.generator,
                self.tokenizer,
                request.text,
                request.labels
            )
            
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