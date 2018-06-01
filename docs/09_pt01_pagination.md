# 09 Pagination Pt 1

## Enable Submitting Messages
We need a form to enter new messages.  
Create a new form model in `app/forms.py`.
```python
class PostForm(FlaskForm):
    post  = TextAreaField('Say something', validators=[DataRequired(), Length(min=1, max=140)])
    submit = SubmitField('Submit')
```
Add the form to the template for the main page (`app/index.html`). Inside the content block:
```python
<h1>Hi, {{ current_user.username }}!</h1>
<form action="" method="post">
  {{ form.hidden_tag() }}
  <p>
    {{ form.post.label }}<br>
    {{ form.post(cols=32, rows=5 ) }}
    {% for error in form.post.errors %}
      <span style="color:red;">[{{ error }}]</span>
    {% endfor %}
  </p>
</form>
{% for post in posts %}
<div><p>{{ post.author.username }} says: <b>{{ post.body }}</b></p></div>
{% endfor %}
```
Provide the form processing on the `index()` view.
```python
from app.forms import PostForm
from app.models import Post

@app.route('/', methods=['GET', 'POST'])
@app.route('/index', methods=['GET', 'POST'])
@login_required
def index():
    form = PostForm()
    if form.validate_on_submit():
        post = Post(body=form.post.data, author=current_user)
        db.session.add(post)
        db.session.commit()
        flash('Your post is now live!')
        return redirect(url_for('index'))
    posts = [
        {'author': {'username': 'John'}, 'body': 'Beautiful day in Portland!'},
        {'author': {'username': 'Susan'},'body': 'The Avengers movie was so cool!'}
    ]
    return render_template("index.html", title='Home Page', form=form, posts=posts)
```
Run the project. Add a sample post, and check the database.

## Display Messages
Make sure that the page displays actual messages.  
Make sure the `index()` view provides real posts by the user and other people the user follows.
```python
def index():
    # [...]
    posts = current_user.followed_posts().all()
    return render_template('index.html', title='Home', posts=posts, form=form)
```
Run the project and check the functionality.

## Make it Easier to Find Users to Follow
Provide a new page - 'Explore'. The page will show a global message stream from all users.  
Start with the view function.  
```python
@app.route('/explore')
@login_required
def explore():
    posts = Post.query.order_by(Post.timestamp.desc()).all()
    # Will use the same template as the index page.
    return render_template('index.html', title='Explore', posts=posts)
```
The view doesn't provide the form variable, so to prevent the web page from crashing, wrap the form in a conditional on the template.
```python
{% block content %}
    <h1>Hi, {{ current_user.username }}!</h1>
    {% if form %}
    <form action="" method="post">
      ...
    </form>
    {% endif %}
```
Add a link to the nav bar (`app/templates/base.html`).
```python
<a href="{{ url_for('explore') }}">Explore</a>
```
In each post, provide a link to the author's profile (`app/profiles/_post.html`).
```python
<td>
  <p>
    <a href="{{ url_for('user', username=post.author.username) }}">
      {{ post.author.username }}
    </a>
   says: <strong>{{ post.body }}</strong></p>
</td>
```
Display the posts using this subtemplate on the index page.
```python
{% for post in posts %}
  {% include "_post.html" %}
{% endfor %}
```
Run the project and check the functionality.

## Paginate Blog Posts

## Provide Page Navigation

## Paginate in the User Profile Page

##
