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

user_dataframe = pd.DataFrame(columns=[
    'username', 'class', 'question1', 'question2', 'question3', 'question4', 'question5',
    'spelling_accuracy', 'stutter_metric', 'speaking_accuracy', 'handwriting_metric', 'total_score'
])

@app.route('/handwriting_analysis', methods=['POST'])
def handwriting_analysis():
    image = request.files['image']
    response = handwriting_test("Apple", image)
    return jsonify(response=response)




if __name__ == '__main__':
    app.run(debug=True, host="192.168.1.213", port=8442)