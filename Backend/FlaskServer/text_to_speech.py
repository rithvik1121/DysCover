from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs
from elevenlabs import play, save
import os

load_dotenv()

client = ElevenLabs(
    api_key=os.getenv("ELEVENLABS_API_KEY"),
)

def create_audio(app, text, filename="output.mp3"):
    audio_folder = os.path.join(app.static_folder, 'tts')
    
    # make dir if not exists
    if not os.path.exists(audio_folder):
        os.makedirs(audio_folder)
    
    filepath = os.path.join(audio_folder, filename)
    
    audio = client.text_to_speech.convert(
        text=text,
        voice_id="56AoDkrOh6qfVPDXZ7Pt",
        model_id="eleven_flash_v2",
        output_format="mp3_22050_32",
        )
    print(filepath)
    save(audio, filepath)
    
    return filepath
