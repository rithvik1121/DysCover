from flask import Flask, request, send_file
from dotenv import load_dotenv
import os

from text_to_speech import create_audio
from speech_to_text import transcribe_audio

# loading env vars
load_dotenv()

app = Flask(__name__, static_folder='static')

TTS_FOLDER = os.path.join(app.root_path, 'static/tts')
STT_FOLDER = os.path.join(app.root_path, 'static/stt')

@app.route('/index')
def index():
    return 'Hello World'

@app.route('/text_to_speech', methods=['POST'])
def text_to_speech():
    text = request.form['text']
    try:
        audio_file = create_audio(app, text)
        return send_file(audio_file, as_attachment=True)
    except ValueError as e:
        return str(e), 500
    
@app.route('/speech_to_text', methods=["POST"])
def speech_to_text():
    try:
        if 'audio' not in request.files:
            return 'No file part', 400
        
        # make dir if not exists
        if not os.path.exists(STT_FOLDER):
            os.makedirs(STT_FOLDER)

        file = request.files['audio']
        if file.filename == '':
            return 'No selected file', 400
        
        # we need to upload file before we can pass it to whisper
        filepath = os.path.join(STT_FOLDER, file.filename)
        file.save(filepath)
        
        text = transcribe_audio(filepath)
        return text
    except ValueError as e:
        return str(e), 500

if __name__ == '__main__':
    app.run(debug=True, host="192.168.1.213", port=8442)
    