from openai import OpenAI
from dotenv import load_dotenv
fron app import STT_FOLDER
import os

load_dotenv()

client = OpenAI(
    api_key = os.getenv('OPENAI_API_KEY')
)

def speech_to_text(file):
    try:
        # make dir if not exists
        if not os.path.exists(STT_FOLDER):
            os.makedirs(STT_FOLDER)

        if file.filename == '':
            return ValueError("No selected file")
        
        # we need to upload file before we can pass it to whisper
        filepath = os.path.join(STT_FOLDER, file.filename)
        file.save(filepath)
        
        text = transcribe_audio(filepath)
        return text
    except ValueError as e:
        return ValueError(f"Speech-to-text failed: {str(e)}")

def transcribe_audio(filepath):
    audio_file = open(filepath, "rb")
    try:    
        transcription = client.audio.transcriptions.create(
            model="whisper-1",
            file=audio_file
        )
        return transcription.text
    except Exception as e:
        raise ValueError(f"Transcription failed: {str(e)}")
