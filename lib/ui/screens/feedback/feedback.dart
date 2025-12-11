import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FeedbackPage extends StatefulWidget {
  final int initialTabIndex;
  const FeedbackPage({Key? key, this.initialTabIndex = 0}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage>
    with SingleTickerProviderStateMixin {
  final feedbackRef = FirebaseFirestore.instance.collection("feedback");
  final currentUser = FirebaseAuth.instance.currentUser;
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _titleController = TextEditingController(text: "General Feedback");
  File? _selectedImage;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this,initialIndex: widget.initialTabIndex);
  }

  @override
  void dispose() {
    _commentController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _submitFeedback() async {
    if (_commentController.text.isEmpty && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Comment or image required")),
      );
      return;
    }

    double avgRating = _categoryRatings.values.isEmpty
        ? 0
        : _categoryRatings.values.reduce((a, b) => a + b) / _categoryRatings.length;

    final feedbackRef = FirebaseFirestore.instance.collection('feedback').doc();

    Uint8List? imageBytes;
    if (_selectedImage != null) {
      imageBytes = await _selectedImage!.readAsBytes();
    }

    await feedbackRef.set({
      "userId": currentUser?.uid,
      "title": _titleController.text.isEmpty
          ? "General Feedback"
          : _titleController.text,
      "status": "Pending",
      "averageRating": avgRating,
      "ratings": Map.from(_categoryRatings),
      "createdAt": FieldValue.serverTimestamp(),
    });

    await feedbackRef.collection("messages").add({
      "user": "You",
      "date": FieldValue.serverTimestamp(),
      "msg": _commentController.text,
      "imageBlob": imageBytes,
    });

    setState(() {
      _titleController.text = "General Feedback";
      _commentController.clear();
      _selectedImage = null;
      _categoryRatings.updateAll((key, value) => 0);
    });

    feedbackRef.collection("messages").snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        final lastMessage = snapshot.docs.last.data() as Map<String, dynamic>;
        if (lastMessage['user'] != 'You') {
          feedbackRef.update({"status": "Responded"});
        }
      }
    });
  }


  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _showSuccessBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.green.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Feedback Received',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thank you! Your opinion matters to us.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ok',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Service Feedback'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Submit Feedback"),
            Tab(text: "My Feedback"),
          ],
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSubmitTab(),
          _buildMyFeedbackTab(),
        ],
      ),
    );
  }

  // ------------------- Submit Feedback Form -------------------
  final Map<String, double> _categoryRatings = {
    'Service Quality': 0,
    'Service Time': 0,
    'Customer Service': 0,
  };

  Widget _buildSubmitTab() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
// ---------------- Feedback Title ----------------
        const Text(
          'Feedback Title',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _titleController,
          decoration: InputDecoration(
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),

        const SizedBox(height: 12),
        const Divider(),
        const SizedBox(height: 12),

        // ---------------- Overall Experience Title ----------------
        const Text(
          "Overall Experience",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),

// ---------------- Subcategories ----------------
        _buildRatingRow("Service Quality"),
        _buildRatingRow("Service Time"),
        _buildRatingRow("Customer Service"),

        const Divider(),
        const SizedBox(height: 16),

        // ---------------- Comment ----------------
        const Text('Feedback', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _commentController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Tell us how we can improve (e.g., waiting time, repair quality)',
            filled: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),

        // ---------- Upload Image Section ----------
        const Text("Attach Image (optional)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (_selectedImage != null)
          Stack(
            alignment: Alignment.topRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: _removeImage,
              )
            ],
          )
        else
          OutlinedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_camera),
            label: const Text("Upload Image"),
          ),
        const SizedBox(height: 20),

        // ---------- Submit Button ----------
        ElevatedButton(
          onPressed: () async {
            await _submitFeedback();
            _showSuccessBottomSheet(context);
          },

          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'Submit',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }


  Widget _buildRatingRow(String category) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(category, style: const TextStyle(fontSize: 14)),
          ),
          RatingBar.builder(
            itemCount: 5,
            initialRating: _categoryRatings[category] ?? 0,
            itemSize: 24,
            itemBuilder: (context, _) =>
            const Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              setState(() {
                _categoryRatings[category] = rating;
              });
            },
          ),
        ],
      ),
    );
  }

// ------------------- My Feedback History -------------------
  String _selectedFilter = "All";

  Widget _buildMyFeedbackTab() {

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: ["All", "Pending", "Reviewed", "Responded"].map((status) {
              final isSelected = _selectedFilter == status;
              return ChoiceChip(
                label: Text(status),
                selected: isSelected,
                onSelected: (_) {
                  setState(() {
                    _selectedFilter = status;
                  });
                },
                selectedColor: Colors.black,
                backgroundColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              );
            }).toList(),
          ),
        ),

        // ----------- Feedback List -----------
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: (_selectedFilter == "All")
                ? FirebaseFirestore.instance
                .collection("feedback")
                .where("userId", isEqualTo: currentUser?.uid)
                .orderBy("createdAt", descending: true)
                .snapshots()
                : FirebaseFirestore.instance
                .collection("feedback")
                .where("userId", isEqualTo: currentUser?.uid)
                .where("status", isEqualTo: _selectedFilter)
                .orderBy("createdAt", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No feedback yet"));
              }

              final docs = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final feedback = docs[index].data() as Map<String, dynamic>;
                  final avgRating =
                  (feedback["averageRating"] as num?)?.toDouble();

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ExpansionTile(
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ---- Feedback Title ----
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  feedback["title"] ?? "General Feedback",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              _buildStatusChip(feedback["status"]),
                            ],
                          ),

                          // ---- Avg Rating below title ----
                          if (avgRating != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Text("Avg: ",
                                      style: TextStyle(fontSize: 13)),
                                  RatingBarIndicator(
                                    rating: avgRating,
                                    itemCount: 5,
                                    itemSize: 18,
                                    itemBuilder: (context, _) => const Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    avgRating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      // ---- Expansion content ----
                      children: [
                        StreamBuilder<QuerySnapshot>(
                          stream: docs[index].reference
                              .collection("messages")
                              .orderBy("date", descending: false)
                              .snapshots(),
                          builder: (context, threadSnapshot) {
                            if (!threadSnapshot.hasData) return Container();

                            final messages = threadSnapshot.data!.docs;
                            if (messages.isEmpty) {
                              return const ListTile(
                                title: Text("No messages yet"),
                              );
                            }

                            return Column(
                              children: messages.map((msgDoc) {
                                final msg =
                                msgDoc.data() as Map<String, dynamic>;
                                final date =
                                (msg["date"] as Timestamp?)?.toDate();
                                final formattedDate = date != null
                                    ? DateFormat('dd MMM, HH:mm').format(date)
                                    : "Unknown date";

                                return ListTile(
                                  dense: true,
                                  title: Text(
                                    "${msg["user"]} ($formattedDate)",
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  subtitle: Text(msg["msg"] ?? ""),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        )
      ],
    );
  }


// ------------------- Status Badge -------------------
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case "Responded":
        color = Colors.green;
        break;
      case "Reviewed":
        color = Colors.orange;
        break;
      default:
        color = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

}