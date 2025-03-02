from flask import Flask, request, send_file, jsonify, g
from text_to_speech import create_audio
from speech_to_text import transcribe_audio
from data.words import QUESTION_ONE_WORDS, QUESTION_THREE_WORDS, QUESTION_FOUR_WORDS, QUESTION_FIVE_PHRASES
import os
import random
import pandas as pd
import sqlite3
from image_rec import handwriting_test

app = Flask(__name__)

@app.route('/handwriting_analysis', methods=['POST'])
def handwriting_analysis():
    image = request.files['image']
    response = handwriting_test("Apple", image)
    return jsonify(response=response)

@app.route('/question_five', methods=['GET'])
def question_five_get():
    phrase = random.choice(QUESTION_FIVE_PHRASES)
    
    return jsonify({'phrase': phrase})

@app.route('/question_five', methods=['POST'])
def question_five_post():
    UPLOAD_FOLDER = 'static/handwritten_image'
    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400
    image_file = request.files['image']
    filename = image_file.filename
    file_path = os.path.join(UPLOAD_FOLDER, filename)
    image_file.save(file_path)
    print(f"Received handwriting image: {file_path}")
    # Here you would process and grade the image.
    return jsonify({'message': 'Handwriting image received successfully'}), 200


if __name__ == '__main__':
    app.run(debug=True, host="192.168.1.213", port=8442)