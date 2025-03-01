from openai import OpenAI
from dotenv import load_dotenv
import os

load_dotenv()

client = OpenAI(
    api_key = os.getenv('OPENAI_API_KEY')
)

def transcribe_audio(filepath):
    try:    
        transcription = client.audio.transcriptions.create(
            model="whisper-1",
            file=filepath
        )
        return transcription.text
    except Exception as e:
        raise ValueError(f"Transcription failed: {str(e)}")
