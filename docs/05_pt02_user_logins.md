# 05 User Logins Pt 2

## Show User in Templates
Improve the `index.html` template.
```python
{% extends "base.html" %}
{% block content %}
    <h1>Hi, {{ current_user.username }}!</h1>
    {% for post in posts %}
    <div><p>{{ post.author.username }} says: <b>{{ post.body }}</b></p></div>
    {% endfor %}
{% endblock %}
```
Remove the `user` argument from the `index()` view.  
Create the first user in a shell.  
```python
u = User(username='susan', email='susan@example.com')
u.set_password('cat')
db.session.add(u)
db.session.commit()
```
Start the app, go to the root ('/'), or to the index ('/index') URL.

## Provide User Registration
Create a new form model (`app/forms.py`).
```python
from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, BooleanField, SubmitField
from wtforms.validators import DataRequired, ValidationError, Email, EqualTo
from app.models import User
# [...]
class RegistrationForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired()])
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    password2 = PasswordField('Repeat Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Register')
    def validate_username(self, username):
        user = User.query.filter_by(username=username.data).first()
        if user is not None:
            raise ValidationError('Please use a different username')
    def validate_email(self, username):
        user = User.query.filter_by(email=email.data).first()
        if user is not None:
            raise ValidationError('Please use a different email')
```
Provide a new template.
```
touch app/templates/register.html
```
See the code [here](../app/templates/register.html).

Provide the link from the login form to the registration page (`app/templates/login.html`).
```html
<p>New user? <a href="{{ url_for('register') }}">Click to Register!</a> </p>
```
Write the view for the registrations.
```python
@app.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('index'))
    form = RegistrationForm()
    if form.validate_on_submit():
        user = User(username=form.username.data, email=form.email.data)
        user.set_password(form.password.data)
        db.session.add(user)
        db.session.commit()
        flash('Congratulations, you are now a registered user!')
        return redirect(url_for('login'))
    return render_template('register.html', title='Register', form=form)
```

NEXT UP
* [06 Profile Page and Avatars](06_profile_avatars.md)
