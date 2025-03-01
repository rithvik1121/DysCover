from dotenv import load_dotenv
from deepgram import DeepgramClient, SpeakOptions
import os

# deepgram client
dg_client = DeepgramClient(os.getenv('DEEPGRAM_API_KEY'))
options = SpeakOptions(model="aura-luna-en")

# Text-to-Speech
def create_audio(app, text):
    try:
        audio_folder = os.path.join(app.static_folder, 'audio')
        
        # make dir if not exists
        if not os.path.exists(audio_folder):
            os.makedirs(audio_folder)
        
        filename = os.path.join(app.static_folder, audio_folder, "output.mp3")
        dg_client.speak.v("1").save(filename, {"text":text}, options)
        return filename
    
    except Exception as e:
        raise ValueError(f"Speech synthesis failed: {str(e)}")