FROM python:3.8

EXPOSE 80

WORKDIR /app

COPY requirements.txt .

RUN pip3 install -r requirements.txt

COPY bookstore-api.py .

CMD [ "python", "bookstore-api.py" ]