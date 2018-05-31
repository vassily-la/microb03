# 08 Followers

## Database Model Representation
Provide the relationship table.
```python
followers = db.Table('followers',
    db.Column('follower_id', db.Integer, db.ForeignKey('user.id')),
    db.Column('followed_id', db.Integer, db.ForeignKey('user.id'))
)
```
Declare the relationship in the users table.
```python
class User(UserMixin, db.Model):
    # [...]
    followed = db.relationship(
        'User', secondary=followers,
        primaryjoin=(followers.c.follower_id == id),
        secondaryjoin=(followers.c.followed_id == id),
        backref = db.backref('followers', lazy='dynamic'),
        lazy='dynamic'
    )
```
Migrate and upgrade
```
flask db migrate -m "Add followers"
flask db upgrade
```

## Add and Remove "follows"
What we have now.
```python
# user 1 follows user 2
user1.followed.append(user2)
# user 1 unfollows user 2
user1.followed.remove(user2)
```
No nice, huh? Defenitely, something like `user1.follow(user2)` would like much better.  
So let's add methods `follow()` and `unfollow()`.
```python
class User(UserMixin, db.Model):
    # [...]
    def follow(self, user):
        if not self.is_following(user):
            self.followed.append(user)
    def unfollow(self, user):
        if self.is_following(user):
            self.followed.remove(user)
    def is_following(self, user):
        is_following = self.followed.filter(followers.c.followed_id = user.id)
        return is_following.count() == 1
```

# Obtain Posts from Followed Users
This one is tricky.
```python
class User(db.Model):
    #...
    def followed_posts(self):
        return Post.query.join(
            followers, (followers.c.followed_id == Post.user_id)).filter(
                followers.c.follower_id == self.id).order_by(
                    Post.timestamp.desc())
```

## Combine Own and Followed Posts
```python
def followed_posts(self):
    followed = Post.query.join( followers, ( followers.c.followed_id == Post.user_id )).filter( followers.c.follower_id == self.id)
    own = Post.query.filter_by(user_id = self.id)
    return followed.union(own).order_by(Post.timestamp.desc())
```

##  Unit Test the User Model
```python
from datetime import datetime, timedelta
import unittest
from app import app, db
from app.models import User, Post

class UserModelCase(unittest.TestCase):
    def setUp(self):
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite://'
        db.create_all()
    def tearDown(self):
        db.session.remove()
        db.drop_all()

    def test_password_hashing(self):
        u = User(username='susan')
        u.set_password('bananas')
        self.assertFalse(u.check_password('apples'))
        self.assertTrue(u.check_password('bananas'))

    def test_follow(self):
        u1 = User(username='john', email='john@example.com')
        u2 = User(username='susan', email='susan@example.com')
        db.session.add(u1)
        db.session.add(u2)
        db.session.commit()
        self.assertEqual(u1.followed.all(), [])
        self.assertEqual(u1.followers.all(), [])

        u1.follow(u2)
        db.session.commit()
        self.assertTrue(u1.is_following(u2))
        self.assertEqual(u1.followed.count(), 1)
        self.assertEqual(u1.followed.first().username, 'susan')
        self.assertEqual(u2.followers.count(), 1)
        self.assertEqual(u2.followers.first().username, 'john')

        u1.unfollow(u2)
        db.session.commit()
        self.assertFalse(u1.is_following(u2))
        self.assertEqual(u1.followed.count(), 0)
        self.assertEqual(u2.followers.count(), 0)

    def test_follow_posts(self):
        # create four users
        u1 = User(username='john', email='john@example.com')
        u2 = User(username='susan', email='susan@example.com')
        u3 = User(username='mary', email='mary@example.com')
        u4 = User(username='david', email='david@example.com')
        db.session.add_all([u1, u2, u3, u4])

        # Create four posts
        now = datetime.utcnow()
        p1 = Post(body='post from john', author = u1, timestamp = now +timedelta(seconds=1))
        p2 = Post(body="post from susan", author=u2,
                  timestamp=now + timedelta(seconds=4))
        p3 = Post(body="post from mary", author=u3,
                  timestamp=now + timedelta(seconds=3))
        p4 = Post(body="post from david", author=u4,
                  timestamp=now + timedelta(seconds=2))
        db.session.add_all([p1, p2, p3, p4])
        db.session.commit()

        # Set up the followers
        u1.follow(u2)  # john follows susan
        u1.follow(u4)  # john follows david
        u2.follow(u3)  # susan follows mary
        u3.follow(u4)  # mary follows david
        db.session.commit()
        # Check the followed posts for each user
        f1 = u1.followed_posts().all()
        f2 = u2.followed_posts().all()
        f3 = u3.followed_posts().all()
        f4 = u4.followed_posts().all()
        self.assertEqual(f1, [p2, p4, p1])
        self.assertEqual(f2, [p2, p3])
        self.assertEqual(f3, [p3, p4])
        self.assertEqual(f4, [p4])

if __name__ == '__main__':
    unittest.main(verbosity=2)
```
Terminal 1: `flask run`
Terminal 2: `python tests.py`

## Intergrate Followers with the App
