from flask import Flask, request, send_file, jsonify, g
from text_to_speech import create_audio
from speech_to_text import transcribe_audio
from data.words import QUESTION_ONE_WORDS, QUESTION_THREE_WORDS, QUESTION_FOUR_WORDS, QUESTION_FIVE_PHRASES
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
    'question1': "",
    'question2': "", 
    'question3': "",
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
    """
    Counts the number of differing letters and extra letters in user_input compared to correct.
    
    :param correct: The correct answer.
    :param user_input: The user's input.
    :return: The number of differing and extra letters.
    """
    # Count character differences up to the length of the shorter string
    diff_count = sum(c1 != c2 for c1, c2 in zip(correct, user_input))
    
    # Count extra characters in the user input
    extra_count = abs(len(user_input) - len(correct))
    
    return diff_count + extra_count

def percent_correct(correct: str, user_input: str) -> float:
    """
    Calculates the relative percent correct based on character differences.

    :param correct: The correct answer.
    :param user_input: The user's input.
    :return: Percentage of correctness (0-100%).
    """
    diff_count = count_differences(correct, user_input)
    max_length = max(len(correct), len(user_input))  # Normalize against longer word
    
    accuracy = (1 - diff_count / max_length) * 100
    return max(accuracy, 0)  

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
    #fix this to reset frame values
    user_dataframe.drop(user_dataframe.index, inplace=True)
    user_dataframe.loc[0, user_dataframe.columns[0]] = username
    print(user_dataframe.head())
    return jsonify({'message': f'User {username} started successfully'}), 200 

@app.route('/question_one', methods=['GET'])
def question_one_get():
    word = random.choice(QUESTION_ONE_WORDS).lower()
    CORRECT_ANSWER["question1"] = word
    audio_path = create_audio(app, word, "word.mp3")
    print(audio_path)
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

    question_two_answer = data['question_two_answer']
    print(question_two_answer)

    if question_two_answer.lower() == CORRECT_ANSWER["question2"]:
        user_dataframe.loc[0, user_dataframe.columns[3]] = 'correct'
    else:
        user_dataframe.loc[0, user_dataframe.columns[3]] = 'incorrect'

    print(user_dataframe.head())
    return jsonify({'message': f'Question 2 graded successfully!'}), 200

@app.route('/question_three', methods=['GET'])
def question_three_get():
    word = random.choice(QUESTION_THREE_WORDS)
    CORRECT_ANSWER["question3"] = word
    return jsonify({'word_prompt': word}), 200

@app.route('/question_three', methods=['POST'])
def question_three_post():
    UPLOAD_FOLDER = 'static/stt'
    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400

    audio_file = request.files['audio']
    file_path = os.path.join(UPLOAD_FOLDER, "output.m4a")
    audio_file.save(file_path)
    print(f"Received audio file: {file_path}")
    
    try:
        text = transcribe_audio(file_path)
        print(text)
        if CORRECT_ANSWER['question3'].lower() == text.lower():
            user_dataframe.loc[0, user_dataframe.columns[4]] = 'correct'
            user_dataframe.loc[0, user_dataframe.columns[9]] = "yes"
            
        else:
            user_dataframe.loc[0, user_dataframe.columns[4]] = 'incorrect'
            user_dataframe.loc[0, user_dataframe.columns[9]] = "no"
            
    except Exception as e:
        return jsonify({'error': f'Transcription failed, {str(e)}'}), 500
    
    return jsonify({'message': 'Question 3 audio received successfully'}), 200


@app.route('/question_four', methods=['GET'])
def question_four_get():
    word = random.choice(QUESTION_FOUR_WORDS)
    print(word)
    return jsonify({'word_prompt': word}), 200

@app.route('/question_four', methods=['POST'])
def question_four_post():
    UPLOAD_FOLDER = 'static/waveforms'
    if not os.path.exists(UPLOAD_FOLDER):
        os.makedirs(UPLOAD_FOLDER)
    if 'audio' not in request.files:
        return jsonify({'error': 'No audio file provided'}), 400

    audio_file = request.files['audio']
    filename = audio_file.filename
    file_path = os.path.join(UPLOAD_FOLDER, filename)
    audio_file.save(file_path)
    print(f"Received audio file: {file_path}")
    
    #ISHANNNNNN GRADE IT HEREEEEEE
    
    return jsonify({'message': 'Question 3 audio received successfully'}), 200
    
    
@app.route('/question_five', methods=['GET'])
def question_five_get():
    phrase = random.choice(QUESTION_FIVE_PHRASES)
    print(phrase)
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


@app.route('/finish_test', methods=['POST'])
def finish_test():
    db, cursor = get_db()
    
    if user_dataframe.empty:
        return jsonify({'error': 'No test data to save'}), 400

    test_data = user_dataframe.iloc[0].to_dict()

    cursor.execute("""
        INSERT INTO data (
            username, class, question1, question2, question3, question4, question5, 
            spelling_accuracy, stutter_metric, speaking_accuracy, handwriting_metric, total_score
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """, (
        test_data.get('username', 'Unknown'),
        test_data.get('class', 'N/A'),
        test_data.get('question1', 'N/A'),
        test_data.get('question2', 'N/A'),
        test_data.get('question3', 'N/A'),
        test_data.get('question4', 'N/A'),
        test_data.get('question5', 'N/A'),
        test_data.get('spelling_accuracy', 0),
        test_data.get('stutter_metric', 'N/A'),
        test_data.get('speaking_accuracy', 'N/A'),
        test_data.get('handwriting_metric', 0),
        test_data.get('total_score', 0),
    ))

    db.commit()  
    print(f"Test data saved for user: {test_data.get('username', 'Unknown')}")

    return jsonify({'message': 'Test results saved successfully'}), 200


if __name__ == '__main__':
    app.run(debug=True, host="192.168.1.213", port=8443)