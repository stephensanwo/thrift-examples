import unittest
from server import LanguageModelHandler
from llm.ttypes import TextGenerationRequest, TextClassificationRequest

class TestLanguageModelHandler(unittest.TestCase):
    def setUp(self):
        self.handler = LanguageModelHandler()

    def test_generate_text(self):
        request = TextGenerationRequest(
            prompt="Hello, how are you?",
            max_length=100,
            temperature=0.7,
            top_p=0.95,
            top_k=50
        )
        
        response = self.handler.generateText(request)
        
        self.assertIsNotNone(response)
        self.assertIsInstance(response.generated_text, str)
        self.assertGreater(len(response.generated_text), 0)
        self.assertGreater(response.generation_time, 0)
        self.assertGreater(response.input_tokens, 0)
        self.assertGreater(response.generated_tokens, 0)

    def test_classify_text(self):
        request = TextClassificationRequest(
            text="I love this product!",
            labels=["positive", "negative", "neutral"]
        )
        
        response = self.handler.classifyText(request)
        
        self.assertIsNotNone(response)
        self.assertIn(response.label, request.labels)
        self.assertGreater(response.confidence, 0)
        self.assertLess(response.confidence, 1)
        self.assertGreater(response.classification_time, 0)

if __name__ == '__main__':
    unittest.main() 