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
    return 'this is thr subpage of third'

@app.route('/fourth/<string:id>')
def fourth(id):
    return f'Id number of this page is {id}'



if __name__ == '__main__':
    app.run(debug=True)