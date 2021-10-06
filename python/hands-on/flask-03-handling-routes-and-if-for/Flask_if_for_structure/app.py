from logging import debug
from flask import Flask, render_template
from flask.signals import message_flashed

app = Flask(__name__)

@app.route('/')
def head():
    first = 'this is my first condition experience'
    return render_template('index.html', message = first)











if __name__ == '__main__':
    app.run(debug = True)