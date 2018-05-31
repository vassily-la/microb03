# 05 User Logins Pt 1

## Password Hashing
Example:
```python
>>> from werkzeug.security import generate_password_hash
>>> hash = generate_password_hash('foobar')
>>> hash
'pbkdf2:sha256:50000$qHOsq310$4d32402199c9450d7b670d206eca911b43471d5ba8cc8e937f0ad43a7d5106ca'
>>> from werkzeug.security import check_password_hash
>>> check_password_hash(hash, 'foobar')
True
>>> check_password_hash(hash, 'barfoo')
False
```
Update models - methods for settings and checking passwords.
```python
from werkzeug.security import generate_password_hash, check_password_hash
...
class User(db.Model):
    # [...]
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
```
Check how things work.
```python
>>> u = User(username='susan', email='susan@example.com')
>>> u.set_p
KeyboardInterrupt
>>> u.set_password('bananas')
>>> u.check_password('apples')
False
>>> u.check_password('bananas')
True
u = User(username='susan', email='susan@example.com')
u.set_password('bananas')
u.check_password('apples')
u.check_password('bananas')
```

## Intro to Flask-Login
```shell
(venv) pip install flask-login
```
Create and initialize and object (`app/__init__.py`).
```python
# ...
from flask_login import LoginManager
app = Flask(__name__)
# ...
login = LoginManager(app)
```

## Provide the Mixin for the User Model
Flask-Login provides the `UserMixin` mixin class that provide properties and a method.
* `is_authenticated` does the user have valid creds?
* `is_active` Is the account active?
* `is_anonymous` false for loggedin, true otherwise
* `get_id()` return a unique id for the user as a string
Implement.
```python
# ...
from flask_login import UserMixin

class User(UserMixin, db.Model):
    # ...
```


## Provide the User Loader Function
FL keeps track of user by storing their UID in a user session.  
Retrieves the ID at each user request.  
Provide in in `app/models.py`.
```python
from app import login
# ...

@login.user_loader
def load_user(id):
    return User.query.get(int(id))
```

## Log Users In
Before: fake login, just a `flash()` message.  
Now, complete the view.
```python
# ...
from flask_login import current_user, login_user
from app.models import User

# ...
@app.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user is None or not user.check_password(form.password.data):
            flash('Invalid username or password')
            return redirect(url_for('login'))
        login_user(user, remember=form.remember_me.data)
        return redirect(url_for('index'))
    return render_template('login.html', title='Sign In', form=form)
```

## Log Users Out
```python
from flask_login import logout_user
# ...
@app.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('index'))
```
Provide the link on the base template.
```html
<div>
    Microblog:
    <a href="{{ url_for('index') }}">Home</a>
    {% if current_user.is_anonymous %}
    <a href="{{ url_for('login') }}">Login</a>
    {% else %}
    <a href="{{ url_for('logout') }}">Logout</a>
    {% endif %}
</div>
```

## Require User Logging
FL needs to know which view handles logins.
```python
# ...
login = LoginManager(app)
login.login_view = 'login'
```
FL provide the function against anonymous users. Can use it in decorators before the views.
```python
from flask_login import login_required
# [...]
@app.route('/')
@app.route('/index')
@login_required
def index():
    # ...
```
But you should provide where to go after the login.  
A url can be `/login?next=/index`.  
How to make it work? See the `login()` view.
```python
from flask import request
from werkzeug.urls import url_parse

@app.route('/login', methods=['GET', 'POST'])
def login():
    # ...
    if form.validate_on_submit():
        user = User.query.filter_by(username=form.username.data).first()
        if user is None or not user.check_password(form.password.data):
            flash('Invalid username or password')
            return redirect(url_for('login'))
        login_user(user, remember=form.remember_me.data)
        next_page = request.args.get('next')
        # This `netlock` thing is important. `
        # It makes sure the link wont forward you to an absolute url
        if not next_page or url_parse(next_page).netloc != '':
            next_page = url_for('index')
        return redirect(next_page)
    # ...
```
Basically, it parses `request.args`.


NEXT UP:
* [05 User Logins Pt 2 - Show User in Template, Register](05_pt02_user_logins.md)
