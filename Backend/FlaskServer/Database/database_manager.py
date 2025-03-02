import sqlite3

conn = sqlite3.connect('user_data.sqlite')
cursor = conn.cursor()

def insert_data(username, class_name, question1, question2, question3, question4, question5, 
                spelling_accuracy, stutter_metric, speaking_accuracy, handwriting_metric, total_score):
    cursor.execute("""
        INSERT INTO data (
            username, class, question1, question2, question3, question4, question5, 
            spelling_accuracy, stutter_metric, speaking_accuracy, handwriting_metric, total_score
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
    """, (username, class_name, question1, question2, question3, question4, question5,
          spelling_accuracy, stutter_metric, speaking_accuracy, handwriting_metric, total_score))
    conn.commit()
    print(f"Data inserted for user: {username}")

def retrieve_data():
    cursor.execute("SELECT * FROM data;")
    rows = cursor.fetchall()
    
    for row in rows:
        print(row)  
    
    return rows

def retrieve_user_data(username):
    cursor.execute("SELECT * FROM data WHERE username = ?;", (username,))
    rows = cursor.fetchall()
    
    if rows:
        for row in rows:
            print(row)
    else:
        print(f"No data found for user: {username}")

    return rows

def retrieve_user_class_data(username, class_name):
    """
    Retrieves all test data for a specific user and class.
    
    :param username: The username to filter by.
    :param class_name: The class name to filter by.
    :return: A list of matching rows.
    """
    cursor.execute("SELECT * FROM data WHERE username = ? AND class = ?;", (username, class_name))
    rows = cursor.fetchall()
    
    if rows:
        print(f"\nData for user '{username}' in class '{class_name}':")
        for row in rows:
            print(row)
    else:
        print(f"No data found for user '{username}' in class '{class_name}'.")

    return rows




cursor.close()
conn.close()
