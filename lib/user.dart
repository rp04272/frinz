import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;

class UserPersonalPage extends StatefulWidget {
  final String userEmail;

  UserPersonalPage({required this.userEmail});

  @override
  _UserPersonalPageState createState() => _UserPersonalPageState();
}

class _UserPersonalPageState extends State<UserPersonalPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController postController = TextEditingController();
  final TextEditingController commentController = TextEditingController();
  final TextEditingController replyController = TextEditingController();
  File? _selectedImage; // Variable to store the selected image


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('SHOW YOUR FRINZ'),
      actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],),
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!) // Use FileImage if _selectedImage is not null
                  : null, 
            ),
            
            SizedBox(height: 20),
            Text(
              'Welcome, ${widget.userEmail}!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildNewPostForm(),
            SizedBox(height: 20),
            _buildUserPosts(),
          ],
        ),
      ),
    );
  }
  

  Widget _buildNewPostForm() {
  return Column(
    children: [
      TextFormField(
        controller: postController,
        decoration: InputDecoration(labelText: 'Write your post'),
      ),
      SizedBox(height: 8),
      _selectedImage != null
          ? Image.file(
              _selectedImage!,
              height: 100,
            )
          : SizedBox.shrink(),
      ElevatedButton(
        onPressed: _selectImage,
        child: Text('Select Image'),
      ),
      ElevatedButton(
        onPressed: () async {
          _submitPost(postController.text);
          postController.clear();
          setState(() {
            _selectedImage = null;
          });

          // Navigate back to the user personal page
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => UserPersonalPage(userEmail: widget.userEmail),
            ),
          );
        },
        child: Text('Post'),
      ),
    ],
  );
}


  void _selectImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      setState(() {
        _selectedImage = File(pickedImage.path);
      });
    }
  }
  void _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  void _submitPost(String postContent) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        //if the user is not logged in
        return;
      }

      String? imageUrl;

      if (_selectedImage != null) {
        imageUrl = await _uploadImageToStorage(_selectedImage!);
      }

      // Store the post data in Firestore
      await _firestore.collection('Posts').add({
        'content': postContent,
        'authorId': currentUser.uid,
        'imageUrl': imageUrl, // Adding the image URL to the post
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      
      print('Error submitting post: $e');
    }
  }

  Future<String?> _uploadImageToStorage(File imageFile) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        
        return null;
      }

      final storageRef = firebase_storage.FirebaseStorage.instance
          .ref()
          .child('user_posts')
          .child(currentUser.uid)
          .child(DateTime.now().toString() + '.jpg');

      final task = await storageRef.putFile(imageFile);

      if (task.state == firebase_storage.TaskState.success) {
        final imageUrl = await task.ref.getDownloadURL();
        return imageUrl;
      }
    } catch (e) {
     
      print('Error uploading image: $e');
    }

    return null;
  }

  Widget _buildUserPosts() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('Posts').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error fetching posts');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        List<QueryDocumentSnapshot> posts = snapshot.data!.docs;

        return Column(
          children: posts.map((post) {
            return Column(
              children: [
                _buildPostItem(post),
                _buildCommentsForPost(post.reference),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPostItem(QueryDocumentSnapshot postSnapshot) {
    final post = postSnapshot.data() as Map<String, dynamic>;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(post['content']),
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () => _showDeleteConfirmationDialog(postSnapshot.reference),
              ),
            ],
          ),
          SizedBox(height: 8),
          post['imageUrl'] != null
              ? Image.network(
                  post['imageUrl'],
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : SizedBox.shrink(),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              _showCommentDialog(postSnapshot.reference);
            },
            child: Text('Comment'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog(DocumentReference postRef) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete this post?'),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                _deletePost(postRef);
                Navigator.pop(context);
              },
              child: Text('Delete'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _deletePost(DocumentReference postRef) async {
    try {
      // Delete the post from Firestore
      await postRef.delete();
    } catch (e) {
      // Handle errors here
      print('Error deleting post: $e');
    }
  }


  Widget _buildCommentsForPost(DocumentReference postRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Comments')
          .where('postRef', isEqualTo: postRef)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error fetching comments');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        List<QueryDocumentSnapshot> comments = snapshot.data!.docs;

        return Column(
          children: comments.map((comment) {
            return Column(
              children: [
                _buildCommentItem(comment),
                _buildRepliesForComment(comment.reference),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCommentItem(QueryDocumentSnapshot commentSnapshot) {
    final comment = commentSnapshot.data() as Map<String, dynamic>;

    return Container(
      padding: EdgeInsets.all(8),
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(comment['content']),
          SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              _showReplyDialog(commentSnapshot.reference);
            },
            child: Text('Reply'),
          ),
        ],
      ),
    );
  }

  Widget _buildRepliesForComment(DocumentReference commentRef) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('Replies')
          .where('commentRef', isEqualTo: commentRef)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error fetching replies');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircularProgressIndicator();
        }

        List<QueryDocumentSnapshot> replies = snapshot.data!.docs;

        return Column(
          children: replies.map((reply) {
            return _buildReplyItem(reply);
          }).toList(),
        );
      },
    );
  }

  Widget _buildReplyItem(QueryDocumentSnapshot replySnapshot) {
    final reply = replySnapshot.data() as Map<String, dynamic>;

    return Container(
      padding: EdgeInsets.all(4),
      margin: EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(reply['content']),
    );
  }

  void _showCommentDialog(DocumentReference postRef) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Comment'),
          content: TextFormField(
            controller: commentController,
            decoration: InputDecoration(labelText: 'Write your comment'),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                _submitComment(postRef, commentController.text);
                commentController.clear();
                Navigator.pop(context);
              },
              child: Text('Comment'),
            ),
          ],
        );
      },
    );
  }

  void _submitComment(DocumentReference postRef, String commentContent) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        
        return;
      }

      
      await _firestore.collection('Comments').add({
        'content': commentContent,
        'authorId': currentUser.uid,
        'postRef': postRef,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      
      print('Error submitting comment: $e');
    }
  }

  void _showReplyDialog(DocumentReference commentRef) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Reply'),
          content: TextFormField(
            controller: replyController,
            decoration: InputDecoration(labelText: 'Write your reply'),
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                _submitReply(commentRef, replyController.text);
                replyController.clear();
                Navigator.pop(context);
              },
              child: Text('Reply'),
            ),
          ],
        );
      },
    );
  }

  void _submitReply(DocumentReference commentRef, String replyContent) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
       
        return;
      }

      // Store the reply data in Firestore
      await _firestore.collection('Replies').add({
        'content': replyContent,
        'authorId': currentUser.uid,
        'commentRef': commentRef,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Handle errors here
      print('Error submitting reply: $e');
    }
  }
}

