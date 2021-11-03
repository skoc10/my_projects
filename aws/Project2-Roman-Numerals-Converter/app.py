from flask import Flask, render_template, request
app = Flask(__name__)

def convert(decimal_num):
    roman = {1000: 'M', 900: 'CM', 500: 'D', 400: 'CD', 100: 'C', 90: 'XC',
             50: 'L', 40: 'XL', 10: 'X', 9: 'IX', 5: 'V', 4: 'IV', 1: 'I'}
    num_to_roman = ''
    for i in roman.keys():
        num_to_roman += roman[i] * (decimal_num // i)
        decimal_num %= i
    return num_to_roman

@app.route('/', methods=['GET', 'POST'])
def result():
    if request.method == 'POST':
        alphanum = request.form.get('number')

        if alphanum.isdecimal():
            if (0 < int(alphanum) < 4000):
                return render_template('result.html', number_decimal=alphanum, number_roman=convert(int(alphanum)), developer_name="Selman Koc")
            else:
                return render_template('index.html', not_valid=True, developer_name="Selman Koc")
        else:
            return render_template('index.html', not_valid=True, developer_name="Selman Koc")
    else:
        return render_template('index.html', not_valid=True, developer_name="Selman Koc")

# app.run(host='0.0.0.0', port=80)
if __name__ == '__main__':
    #app.run(debug=True)
    app.run(host='0.0.0.0', port=80)