from logging import debug
from flask import Flask, render_template
from flask.signals import message_flashed

app = Flask(__name__)

@app.route('/')
def head():
    first = 'this is my first condition experience'
    return render_template('index.html', message = first)

@app.route('/skoc')
def mylist():
    names = ['selman', 'samet', 'alp', 'mehmemt']
    return render_template('body.html', object = names)








if __name__ == '__main__':
    #app.run(debug = True)
    app.run(host='0.0.0.0', port=80)