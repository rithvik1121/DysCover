from openai import OpenAI
from dotenv import load_dotenv
import os
import base64

load_dotenv()

client = OpenAI(
    api_key = os.getenv('OPENAI_IMAGE_API_KEY')
)

# Function to encode the image
def encode_image(image_path):
    with open(image_path, "rb") as image_file:
        return base64.b64encode(image_file.read()).decode("utf-8")

def handwriting_test(correct_answer, image):
    folder = "/static/handwritten/"
    if not os.path.exists(folder):
        os.makedirs(folder)
    image_path = folder + "handwriting.png"
    
    image.save(image_path)
    
    encoded_image = encode_image(image_path)
    
    response = client.chat.completions.create(
        model = "gpt-4o",
        messages = [
            {
                "role": "system",
                "content": "You are an expert in handwriting analysis and dyslexia screening. Your task is to evaluate a handwritten word image against the correct reference word. Given an analysis of the handwriting, determine if the user response matches correct response, determine the similarity percentage score, where a lower score suggests a higher likelihood of dyslexia. Keep your output limited to just whether or not the input word is correct, and the percentage match between the input and correct response."
            },
            {
                "role": "user",
                "content": [
                    {
                        "type": "text",
                        "text": f"First, analyze the sample based on the correctness. The weight of correctness should be 50%. Here is the correct answer: {correct_answer}. Then analyze based on the following criteria:\n\n1. **Letter Formation & Alignment** - How closely do the letters match the reference word in shape and positioning?\n2. **Spacing & Consistency** - Are the spaces between letters uniform, and is the handwriting consistent?\n3. **Stroke Quality & Fluidity** - Are the strokes smooth and connected properly, or are they irregular and inconsistent?\n4. **Orientation & Slant** - Does the writing align with the correct orientation and slant?\n\nReturn a **similarity percentage score (0-100%)**, where:\n- 100% = Perfect match to reference word\n- 0% = Extremely poor match, high dyslexia risk, and a yes/no if the response matches the correct answer\nOnly return two pieces of information as output: yes or no if the response is correct, and the percentage match between the input and ground truth. If you cannot determine if the response is correct, return No by default. If you cannot determine the percentage match, return 0% by default."
                    },
                    {
                        "type": "image_url",
                        "image_url": {"url": f"data:image/jpeg;base64,{encoded_image}"}
                    }
                ]
            }
        ]
    )
    
    content = response.choices[0].message.content
    print(content)
    return content
