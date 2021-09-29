from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello():
    return 'Hello World from Flask!!!'

@app.route('/second')
def second():
    return 'Bize her yer Trabzon!!!'

@app.route('/third/subthird')
def third():
    retur 'this page third page'


if __name__ == '__main__':
    app.run(debug=True)