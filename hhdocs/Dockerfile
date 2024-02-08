FROM squidfunk/mkdocs-material

COPY requirements.txt /requirements.txt
RUN pip install -r /requirements.txt

COPY gitconfig /root/.gitconfig

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
