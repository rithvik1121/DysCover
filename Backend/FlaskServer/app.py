from flask import Flask, request, send_file
from deepgram import DeepgramClient, SpeakOptions
from dotenv import load_dotenv
import os

app = Flask(__name__, static_folder='static')

# deepgram client
dg_client = DeepgramClient(os.getenv('DEEPGRAM_API_KEY'))
options = SpeakOptions(model="aura-asteria-en")


@app.route('/index')
def index():
    return 'Hello World'


# Text-to-Speech
def create_audio(text):
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

@app.route('/text_to_speech', methods=['POST'])
def text_to_speech():
    print("first")
    text = request.form['text']
    try:
        audio_file = create_audio(text)
        return send_file(audio_file, as_attachment=True)
    except ValueError as e:
        return str(e), 500

if __name__ == '__main__':
    app.run(debug=True, host="192.168.1.213", port=8442)