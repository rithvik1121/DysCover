from flask import Flask, request, send_file
import os

app = Flask(__name__)

@app.route('/text_to_speech', methods=['POST'])
def text_to_speech():
    text = request.form['text']
    pass

if __name__ == '__main__':
    app.run(debug=True)