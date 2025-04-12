# server.py
from flask import Flask, request, jsonify
import os
import requests

app = Flask(__name__)

UPSTAGE_API_KEY = "up_XA8y5rqH0YSVI722edRwzXn9agOQz"
UPSTAGE_API_URL = "https://api.upstage.ai/v1/document/parse"

OUTPUT_DIR = "output_html"
os.makedirs(OUTPUT_DIR, exist_ok=True)

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'files' not in request.files:
        return jsonify({'error': 'No file part'}), 400

    files = request.files.getlist('files')
    results = []

    for file in files:
        filename = file.filename
        response = requests.post(
            UPSTAGE_API_URL,
            headers={'Authorization': f'Bearer {UPSTAGE_API_KEY}'},
            files={'file': (filename, file.stream, file.content_type)}
        )

        if response.status_code == 200:
            html_output = response.json().get('html', '')
            html_filename = os.path.splitext(filename)[0] + '.html'
            html_path = os.path.join(OUTPUT_DIR, html_filename)

            with open(html_path, 'w', encoding='utf-8') as f:
                f.write(html_output)

            results.append({'filename': filename, 'html_file': html_filename})
        else:
            results.append({
                'filename': filename,
                'error': response.text
            })

    return jsonify(results)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000, debug=True)
