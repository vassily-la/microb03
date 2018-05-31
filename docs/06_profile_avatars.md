# Profile Page and Avatars

Plan:
* Create User Profile Page
* Provide Avatars
* Use Jinja 2 Sub-Templates
* Provide Details
* Record Last Visit
* Create Profile Editor

## Create User Profile Page
Create view.
```python
@app.route('/user/<username>')
@login_required
def user(username):
    user = User.query.filter_by(username=username).first_or_404()
    posts = [
        {'author': user, 'body': "Text post #1"},
        {'author': user, 'body': "Text post #2"},
    ]
    return render_template('user.html', user=user, posts=posts)
```
Create a template (`app/templates/user.html`), provide the User and posts.
```python
{% extends "base.html" %}
{% block content %}
<h1>User: {{ user,username }}</h1>
<hr>
{% for post in posts %}
  <p>
    {{ post.author.username }} says: <strong>{{ post.body }}</strong>
  </p>
{% endfor %}
{% endblock %}
```
Add a link to the base template.
```python
<div>
    Microblog:
    <a href="{{ url_for('index') }}">Home</a>
    {% if current_user.is_anonymous %}
    <a href="{{ url_for('login') }}">Login</a>
    {% else %}
    <a href="{{ url_for('user', username=current_user.username )}}">Profile</a>
    <a href="{{ url_for('logout') }}">Logout</a>
    {% endif %}
</div>
```
## Provide Avatars
Add the avatar method to the model.
```python
from hashlib import md5
# ...
class User(UserMixin, db.Model):
    # ...
    def avatar(self, size):
        digest = md5(self.email.lower().encode('utf-8')).hexdigest()
        return 'https://www.gravatar.com/avatar/{}?d=identicon&s={}'.format(digest, size)
```
Render the avatar on the template, up top and on the individual posts (`app/templates/user.html`).
```python
{% extends "base.html" %}
{% block content %}
<table>
  <tr valign="top">
    <td><img src="{{ user.avatar(128) }}" alt=""></td>
    <td><h1>User: {{ user.username }}</h1></td>
  </tr>
</table>
<hr>
{% for post in posts %}
<table>
  <tr valign="top">
    <td><img src="{{ post.author.avatar(36) }}" alt=""> </td>
    <td><p>{{ post.author.username }} says: <strong>{{ post.body }}</strong></p></td>
  </tr>
</table>
{% endfor %}
{% endblock %}
```
Show avatars on individual posts.

## Use Jinja 2 Sub-Templates
A subtemplate for individual posts on the index page and on the user pages (`index.html` and `user.html`).  
Create the sub-template.
```
touch app/templates/_post.html
```
Copy and paste the code inside the for loop on the `user.html` template.
```html
<table>
  <tr valign="top">
    <td><img src="{{ post.author.avatar(36) }}" alt=""> </td>
    <td><p>{{ post.author.username }} says: <strong>{{ post.body }}</strong></p></td>
  </tr>
</table>
```
Use the `include` statement inside the `for` loop on the `user.html` template.
```python
{% for post in posts %}
  {% include "_post.html" %}
{% endfor %}
```
'index.html' will be updated later.  
Run and check whether this works.  

## Provide Details
Add two fields to the `User` model.
```python
class User(UserMixin, db.Model):
    # [...]
    about_me = db.Column(db.String(140))
    last_seen = db.Column(db.DateTime(), default=datetime.utcnow)
```
Migrate and update.  
```shell
(flsk) $ flask db migrate -m "Add about and st_seen to the User model"
INFO  [alembic.runtime.migration] Context impl SQLiteImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.autogenerate.compare] Detected added column 'user.about_me'
INFO  [alembic.autogenerate.compare] Detected added column 'user.last_seen'
  Generating /home/vl/Learn/mi/microblog-0.3/migrations/versions/41abdff7d355_add_
  about_and_last_seen_to_the_user_.py ... done
(flsk) $ flask db upgrade
INFO  [alembic.runtime.migration] Context impl SQLiteImpl.
INFO  [alembic.runtime.migration] Will assume non-transactional DDL.
INFO  [alembic.runtime.migration] Running upgrade 1ac5df57e83e -> 41abdff7d355, Add about and last_seen to the User model
```
Add the fields to the user profile template.
```html
<tr valign="top">
  <td> <img src="{{ user.avatar(128) }}" alt=""></td>
  <td>
    <h1>User: {{ user.username }}</h1>
    {% if user.about_me %}<p>{{ user.about_me }}</p>{% endif %}
    {% if user.last_seen %} <p>Last seen on: {{ user.last_seen }}</p> {% endif %}
  </td>
</tr>
```

## Record Last Visit Time
Flask apps provide this as a native feature.  
Implement inside the app/routes.py
```python
from datetime import datetime

# Flask's `@before_request` decorator register the decorated function to be executed right before the view function.
@app.before_request
def before_request():
    if current_user.is_authenticated:
        current_user.last_seen = datetime.utcnow()
        db.session.commit()
```
Run and check.

## Create Profile Editor
Create a form in `app/forms.py`.
```python
from wtforms import StringField, TextAreaField, SubmitField
from wtforms.validators import DataRequired, Length
# ...
class EditProfileForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    about_me = TextAreaField('About me', validators=[Length(min=0, max=140)])
    submit = SubmitField('Submit')
```
Create the template (`app/templates/edit_profile.html`).
```python
<form action="" method="post">
  {{ form.hiddent_tag() }}
  <p>
    {{ form.username.label }}<br>
    {{ form.username(size=32)}}<br>
    {% for error in form.username.errors %}
    <span style="color:red;">[{{ error }}]</span>
    {% endfor %}
  </p>
  <p>
    {{ form.about_me.label }}<br>
    {{ form.about_me(cols=50, rows=4)}}<br>
    {% for error in form.about_me.errors %}
    <span style="color:red;">[{{ error }}]</span>
    {% endfor %}
  </p>
  <p>{{ form.submit() }}</p>
</form>
```
Provide the view function.
```python
from app.forms import EditProfileForm

@app.route('/edit_profile', methods=['GET', 'POST'])
@login_required
def edit_profile():
    form = EditProfileForm()
    if form.validate_on_submit():
        # Copy data from the form to the object
        current_user.username = form.username.data
        current_user.about_me = form.about_me.data
        db.session.commit()
        flash('Your changes have been saved.')
        return redirect(url_for('edit_profile'))
    elif request.method == 'GET':
        # Provide the initial data
        form.username.data = current_user.username
        form.about_me.data = current_user.about_me
    return render_template('edit_profile.html', title='Edit Profile', form=form)
```
Add the link to the profile template (`user.html`).
```python
{% if user == current_user %}
<p><a href="{{ url_for('edit_profile') }}">Edit your profile</a></p>
{% endif %}
```
Check how it works.

NEXT UP:
* [07 Error Handling Pt 1](07_pt01_error_handling.md)
