FROM python:alpine
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt
WORKDIR /app
COPY ./bookstore-api.py /app/ 
EXPOSE 80
CMD python ./bookstore-api.py