from flask import Flask, render_template, request, g, redirect, url_for
import sqlite3

app = Flask(__name__)
DATABASE = "../Backend/FlaskServer/Database/user_data.sqlite"

DIFFICULTY_LEVELS = ["easy", "medium", "hard"]

def get_db():
    db = getattr(g, '_database', None)
    if db is None:
        db = g._database = sqlite3.connect(DATABASE)
        db.row_factory = sqlite3.Row  # enables dict-like row access in templates
    return db

@app.teardown_appcontext
def close_connection(exception):
    db = getattr(g, '_database', None)
    if db is not None:
        db.close()

# Teacher Dashboard: Enter class name and view all students in that class.
@app.route("/", methods=["GET", "POST"])
def index():
    class_name = None
    users = []
    if request.method == "POST":
        class_name = request.form.get("class_name")
        if class_name:
            db = get_db()
            # Select distinct usernames for the class
            cur = db.execute("SELECT DISTINCT username FROM data WHERE class = ?", (class_name,))
            users = cur.fetchall()
    return render_template("index.html", class_name=class_name, users=users)

# Student Dashboard: Display detailed test history and charts for a student.
@app.route("/user/<username>")
def user_dashboard(username):
    db = get_db()
    cur = db.execute("SELECT * FROM data WHERE username = ?", (username,))
    records = cur.fetchall()

    # Aggregate metrics and collect chart data if there are test records.
    if records:
        count = len(records)
        difficulty = 'easy'
        if count > 0:
            difficulty = records[0]['difficulty_level']
            difficulty = DIFFICULTY_LEVELS[difficulty]
        
        total_score_sum = sum(row['total_score'] for row in records if row['total_score'] is not None)
        spelling_sum = sum(row['spelling_accuracy'] for row in records if row['spelling_accuracy'] is not None)
        handwriting_sum = sum(row['handwriting_metric'] for row in records if row['handwriting_metric'] is not None)
        avg_total = round(total_score_sum / count, 2) if count else 0
        avg_spelling = round(spelling_sum / count, 2) if count else 0
        avg_handwriting = round(handwriting_sum / count, 2) if count else 0

        test_ids = [row['test_id'] for row in records]
        total_scores = [row['total_score'] for row in records]
        spelling_scores = [row['spelling_accuracy'] for row in records]
        handwriting_scores = [row['handwriting_metric'] for row in records]
    else:
        avg_total = avg_spelling = avg_handwriting = 0
        test_ids, total_scores, spelling_scores, handwriting_scores = [], [], [], []
        
    return render_template("user_dashboard.html", username=username, records=records, difficulty=difficulty,
                           avg_total=avg_total, avg_spelling=avg_spelling, avg_handwriting=avg_handwriting,
                           test_ids=test_ids, total_scores=total_scores,
                           spelling_scores=spelling_scores, handwriting_scores=handwriting_scores)

@app.route("/user/<username>", methods=["POST"])
def update_user_difficulty(username):
    # Update the difficulty level for a student.
    difficulty = request.json.get("difficulty")
    print(difficulty)
        
    if difficulty not in DIFFICULTY_LEVELS:
        return "Invalid difficulty level."
    
    difficulty = difficulty.lower()
    difficulty_level = DIFFICULTY_LEVELS.index(difficulty)
    db = get_db()
    db.execute("UPDATE data SET difficulty_level = ? WHERE username = ?", (difficulty_level, username))
    db.commit()
    return redirect(url_for("user_dashboard", username=username))


if __name__ == "__main__":
    app.run(host="192.168.1.213", port=8445, debug=True)
