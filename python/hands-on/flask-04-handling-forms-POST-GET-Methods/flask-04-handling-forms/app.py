# Import Flask modules
from flask import Flask, render_template, request

# Create an object named app
app = Flask(__name__)

# Create a function named `home` which uses template file named `main.html` given under `templates` folder,
# send your name as template variable, and assign route of no path ('/')
@app.route("/")
def home():
    return render_template('main.html', name='Vincenzooooo')

# Write a function named `greet` which uses template file named `greet.html` given under `templates` folder. it takes parameters from query string on URL, assign that parameter to the 'user' variable and sent that user name into the html file. If it doesn't have any parameter, warning massage is raised
@app.route("/greet", methods = ["GET"])
def greet():
    if 'user' in request.args:
        myname = request.args['user']
        return render_template('greet.html', user=myname)
    else:
        return render_template('greet.html', user = "Send your user name with 'user' parameter in ? ")

# Write a function named `login` which uses `GET` and `POST` methods,
# and template files named `login.html` and `secure.html` given under `templates` folder
# and assign to the static route of ('login'). It controls If password is clarusway or not
@app.route("/login", methods = ['GET', 'POST'])
def login():
    if request.method == 'POST':
        myname = request.form['username']
        myword = request.form['password']
        if myword == 'awesome-09-cohort':
            return render_template('secure.html', user = myname.title())
        else:
            return render_template('login.html', user = myname.title(), control = True)
    else:
        return render_template('login.html', control = False)

# Add a statement to run the Flask application which can be reached from any host on port 80.
if __name__ == "__main__":
    #app.run(debug=True)
    app.run(host='0.0.0.0', port=80)