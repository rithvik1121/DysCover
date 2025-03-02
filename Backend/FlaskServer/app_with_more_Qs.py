from flask import Flask, request, send_file, jsonify, g
from text_to_speech import create_audio
from speech_to_text import transcribe_audio
from data.words import TESTING_WORDS
import os
import random
import pandas as pd
import sqlite3

app = Flask(__name__)

user_dataframe = pd.DataFrame(columns=[
    'username', 'class', 'question1', 'question2', 'question3', 'question4', 'question5',
    'spelling_accuracy', 'stutter_metric', 'speaking_accuracy', 'handwriting_metric', 'total_score'
])

CORRECT_ANSWER = {
    'question1': None,
    'question2': None, 
    'question3': None,
}

def get_db():
    if 'db' not in g:  # Ensure only one connection per request
        g.db = sqlite3.connect('Database/user_data.sqlite.sqlite')
        g.cursor = g.db.cursor()
    return g.db, g.cursor

@app.teardown_appcontext
def close_db(error=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()
        print("Database connection closed.")

def insert_data(username, class_name, question1, question2, question3, question4, question5, 
                spelling_accuracy, stutter_metric, speaking_accuracy, handwriting_metric, total_score):
    db, cursor = get_db()
    cursor.execute("""
        INSERT INTO data (
            username, class, question1, question2, question3, question4, question5, 
            spelling_accuracy, stutter_metric, speaking_accuracy, handwriting_metric, total_score
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """, (username, class_name, question1, question2, question3, question4, question5,
          spelling_accuracy, stutter_metric, speaking_accuracy, handwriting_metric, total_score))
    db.commit()
    print(f"Data inserted for user: {username}")

def retrieve_data():
    db, cursor = get_db()
    cursor.execute("SELECT * FROM data;")
    rows = cursor.fetchall()
    return rows

def retrieve_user_data(username):
    db, cursor = get_db()
    cursor.execute("SELECT * FROM data WHERE username = ?;", (username,))
    rows = cursor.fetchall()
    return rows

def retrieve_user_class_data(username, class_name):
    db, cursor = get_db()
    cursor.execute("SELECT * FROM data WHERE username = ? AND class = ?;", (username, class_name))
    rows = cursor.fetchall()
    return rows

def count_differences(correct: str, user_input: str) -> int:
    return sum(c1 != c2 for c1, c2 in zip(correct, user_input)) + abs(len(user_input) - len(correct))

def percent_correct(correct: str, user_input: str) -> float:
    diff_count = count_differences(correct, user_input)
    max_length = max(len(correct), len(user_input))  
    return max((1 - diff_count / max_length) * 100, 0)

@app.route('/index')
def index():
    return 'Hello World'

@app.route('/start', methods=['POST'])
def start_test():
    data = request.get_json()
    if not data or 'username' not in data:
        return jsonify({'error': 'Missing username'}), 400

    username = data['username']
    print(username)
    user_dataframe.iloc[0:0]  
    user_dataframe.loc[0, user_dataframe.columns[0]] = username
    print(user_dataframe.head())
    return jsonify({'message': f'User {username} started successfully'}), 200 

@app.route('/question_one', methods=['GET'])
def question_one_get():
    word = random.choice(TESTING_WORDS).lower()
    CORRECT_ANSWER["question1"] = word
    audio_path = create_audio(app, word, "word.mp3")
    return send_file(audio_path, mimetype="audio/mpeg", as_attachment=False)

@app.route('/question_one', methods=['POST'])
def question_one_post():
    data = request.get_json()
    if not data or 'question_one_answer' not in data:
        return jsonify({'error': 'Missing Question 1 Answer'}), 400

    question_one_answer = data['question_one_answer']
    print(question_one_answer)

    if question_one_answer.lower() == CORRECT_ANSWER["question1"]:
        user_dataframe.loc[0, user_dataframe.columns[2]] = 'correct'
        user_dataframe.loc[0, user_dataframe.columns[7]] = 100
    else:
        relative_score = percent_correct(CORRECT_ANSWER["question1"], question_one_answer.lower())
        user_dataframe.loc[0, user_dataframe.columns[2]] = 'incorrect'
        user_dataframe.loc[0, user_dataframe.columns[7]] = relative_score

    print(user_dataframe.head())
    return jsonify({'message': f'Question 1 graded successfully!'}), 200

#same as question 1 but letters instead of words 
@app.route('/question_two', methods=['GET'])
def question_two_get():
    letters = "DBWM"
    CORRECT_ANSWER["question2"] = random.choice(letters).lower()
    audio_path = create_audio(app, CORRECT_ANSWER["question2"], "letter.mp3")
    return send_file(audio_path, mimetype="audio/mpeg", as_attachment=False)

@app.route('/question_two', methods=['POST'])
def question_two_post():
    data = request.get_json()
    if not data or 'question_two_answer' not in data:
        return jsonify({'error': 'Missing Question 1 Answer'}), 400

    question_two_answer = data['question_one_answer']
    print(question_two_answer)

    if question_two_answer.lower() == CORRECT_ANSWER["question2"]:
        user_dataframe.loc[0, user_dataframe.columns[2]] = 'correct'
    else:
        user_dataframe.loc[0, user_dataframe.columns[2]] = 'incorrect'

    print(user_dataframe.head())
    return jsonify({'message': f'Question 2 graded successfully!'}), 200

if __name__ == '__main__':
    app.run(debug=True, host="192.168.1.213", port=8443)
