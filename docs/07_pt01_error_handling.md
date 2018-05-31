# 07 Error Handling

## Model an Error
Log in as one user, go to the Edit Profile page.  
Enter another user's username.
Try saving - Internal Server Error.
Traceback:
```
...
sqlalchemy.exc.IntegrityError: (sqlite3.IntegrityError) UNIQUE constraint failed: user.username [SQL: 'UPDATE user SET username=?, about_me=? WHERE user.id = ?'] [parameters: ('grozi', 'Proud supprter', 2)] (Background on this error at: http://sqlalche.me/e/gkpj)
```
Switch the debug mode on.  
```shell
export FLASK_DEBUG=1
```
Do the same.
Difference: Output a lil' bit different.   
```
(venv) microblog2 $ flask run
 * Serving Flask app "microblog"
 * Forcing debug mode on
 * Running on http://127.0.0.1:5000/ (Press CTRL+C to quit)
 * Restarting with stat
 * Debugger is active!
 * Debugger PIN: 177-562-960
```
Repeat the error.  
Result: Nice Traceback.  

## Reloader
* Tracks the app state.
* Automatically restarts the app when a source file is modified.  

## Create Custom Error Pages
Create a file for the error handlers, and the templates. Error 500: database error (like the error above).
```
touch app/errors.py app/templates/404.html app/templates/500.html
```
Error handlers (`app/errors.py`) are similar to views. Note that we provide the HTTP response code.    Otherwise, `render_template()` will provide code 200 (OK) which is the default value.
```python
from flask import render_template
from app import app, db

@app.errorhandler(404)
def not_found_error(error):
    return render_template('404.html'), 404
@app.errorhandler(500)
def internal_error(error):
    return render_template('500.html'), 500
```
Provide the template for the 404 error.
```html
{% extends "base.html" %}

{% block content %}
    <h1>File Not Found</h1>
    <p><a href="{{ url_for('index') }}">Back</a></p>
{% endblock %}
```
Provide the template for the 500 error.
```html
{% extends "base.html" %}
{% block content %}
    <h1>An unexpected error has occurred</h1>
    <p>The administrator has been notified. Sorry for the inconvenience!</p>
    <p><a href="{{ url_for('index') }}">Back</a></p>
{% endblock %}
```
Get the error handlers registered with Flask.  
To do this, import `app.errors` into `app` (down below the `app/__init__.py`).
```python
from app import routes, models, errors
```
Check the feature.  
Switch off the debug mode, run the app again.
```
export FLASK_DEBUG=0
flask run
```
Duplicate the error.  
Result: nice view.

## Send Errors by Email
Add the following lines to `config.py`.
```python
class Config(object):
    # ...
    MAIL_SERVER = os.environ.get('MAIL_SERVER')
    MAIL_PORT = int(os.environ.get('MAIL_PORT') or 25)
    MAIL_USE_TLS = os.environ.get('MAIL_USE_TLS') is not None
    MAIL_USERNAME = os.environ.get('MAIL_USERNAME')
    MAIL_PASSWORD = os.environ.get('MAIL_PASSWORD')
    ADMINS = ['your-email@example.com']
```
Flask uses Py's `logging` package to write the logs and it already has the SMTP ability.  
To get emails sent out on errors, add an SMTP handler instance to Flask logger object (`app.logger`) in `app/__init__.py`.
```python
if not app.debug:
    if app.config['MAIL_SERVER']:
        auth = None
        if app.config['MAIL_USERNAME'] or app.config['MAIL_PASSWORD']:
            auth = (app.config['MAIL_USERNAME'], app.config['MAIL_PASSWORD'])
        secure = None
        if app.config['MAIL_USE_TLS']:
            secure = ()
        mail_handler = SMTPHandler(
            mailhost=(app.config['MAIL_SERVER'], app.config['MAIL_PORT']),
            fromaddr='no-reply@' + app.config['MAIL_SERVER'],
            toaddrs=app.config['ADMINS'], subject='Microblog Failure',
            credentials=auth, secure=secure)
        mail_handler.setLevel(logging.ERROR)
        app.logger.addHandler(mail_handler)
```
Can you the SMTP debugging server from Python.
```shell
python -m smtpd -n -c DebuggingServer localhost:8025
```
Or configure a real email server. Like this Gmail config:
```shell
export MAIL_SERVER=smtp.googlemail.com
export MAIL_PORT=587
export MAIL_USE_TLS=1
export MAIL_USERNAME=<your-gmail-username>
export MAIL_PASSWORD=<your-gmail-password>
```


## Log to File
Add another handler, `RotatingFileHandler`, and specify.  
```python
from logging.handlers import RotatingFileHandler
import os

# ...

if not app.debug:
    # ...

    if not os.path.exists('logs'):
        os.mkdir('logs')
    file_handler = RotatingFileHandler('logs/microblog.log', maxBytes=10240,
                                       backupCount=10)
    file_handler.setFormatter(logging.Formatter(
        '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'))
    file_handler.setLevel(logging.INFO)
    app.logger.addHandler(file_handler)

    app.logger.setLevel(logging.INFO)
    app.logger.info('Microblog startup')
```

## Fix the Duplicate Username Bug
Update the `EditProfileForm()` class.
```python
class EditProfileForm(FlaskForm):
    # [...]
    # Update the init so
    def __init__(self, original_username, *args, **kwargs):
        super(EditProfileForm, self).__init__(*args, **kwargs)
        self.original_username = original_username
    def validate_username(self, username):
        # Make sure the username doesn't exist already
        if username.data != self.original_username:
            user = User.query.filter_by(username=self.username.data).first()
            if user is not None:
                raise ValidationError('Please use a different username.')
```
Update the view (`app/routes.py`) - add the original username argument.
```python
@app.route('/edit_profile', methods=['GET', 'POST'])
@login_required
def edit_profile():
    form = EditProfileForm(current_user.username)
    ...
```
Reproduce the error and check the folder `logs`.

NEXT UP:
* [08 Followers Pt 1](08_pt01_followers.md)
