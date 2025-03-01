from flask import Flask, request, send_file, jsonify
import os
import pandas as pd

app = Flask(__name__)

user_dataframe = pd.DataFrame(columns=['username', 
                                       'question1', 'question2', 'question3', 'question4', 'question5',
                                       'spelling_accuracy', 'stutter_metric', 'speaking_accuracy', 'handwriting_metric', 'total_score'])

#HELPER FUNCTIONSSSSS
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
    #grab username
    if request.method == 'POST':
        data = request.get_json()  # Correct way to retrieve JSON data
        if not data or 'username' not in data:
            return jsonify({'error': 'Missing username'}), 400
    
    username = data['username']
    print(username)
    #init dataframe
    user_dataframe.iloc[0:0]
    user_dataframe.loc[0, user_dataframe.columns[0]] = username
    print(user_dataframe.head())
    return jsonify({'message': f'User {username} started successfully'}), 200 



@app.route('/question_one', methods=['GET'])
def question_one_get():
    audio_path = "static/audio/output.mp3"  # Path to the audio file
    return send_file(audio_path, mimetype="audio/mpeg", as_attachment=False)
    
@app.route('/question_one', methods=['POST'])
def question_one_post():
    #QUESTION 1 DATA
    correct_answer = "apple"
    
    
    if request.method == 'POST':
        data = request.get_json()
        if not data or 'question_one_answer' not in data:
            return jsonify({'error': 'Missing Question 1 Answer'}), 200
    
    question_one_answer = data['question_one_answer']
    print(question_one_answer)
    #grade answer against correct
    #metric 
    
    #if right answer
    if question_one_answer.lower() == correct_answer:
        #update column 'question1' to correct
        user_dataframe.loc[0, user_dataframe.columns[1]] = 'correct'
        #update column 'spelling_accuracy' to percent correct
        user_dataframe.loc[0, user_dataframe.columns[6]] = 100
        print(user_dataframe.head())

    #if wrong answer
    elif question_one_answer.lower() != correct_answer:
        #get exact score
        relative_score = percent_correct(correct_answer, question_one_answer)
        #update dataframe
        user_dataframe.loc[0, user_dataframe.columns[1]] = 'incorrect'
        user_dataframe.loc[0, user_dataframe.columns[6]] = relative_score

        print(user_dataframe.head())

    
    
    return jsonify({'message': f'Question 1 graded successfully!'}), 200


if __name__ == '__main__':
    app.run(debug=True, host="192.168.1.213", port=8443)  