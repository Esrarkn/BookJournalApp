import 'dart:io';

import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:book_journal/core/theme.dart/appPalette.dart';
import 'package:book_journal/data/bloc/book_bloc/book_bloc.dart';
import 'package:book_journal/data/bloc/book_bloc/book_event.dart';
import 'package:book_journal/data/bloc/book_bloc/book_state.dart';
import 'package:book_journal/ui/models/book.dart';
import 'package:book_journal/ui/widgets/book_image.dart';
import 'package:book_journal/ui/widgets/categorySelector.dart';
import 'package:book_journal/ui/widgets/imageButton.dart';
import 'package:book_journal/ui/widgets/saveButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class BookFormPage extends StatefulWidget {
  final Book? book;
  const BookFormPage({this.book});

  @override
  State<BookFormPage> createState() => _BookFormPageState();
}

class _BookFormPageState extends State<BookFormPage> {
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _summaryController = TextEditingController();
  final _feelingsController = TextEditingController();
  final _quotesController = TextEditingController();
  final _searchController = TextEditingController();

  String? _bookImage;
  bool _showSuggestions = false;
  ReadingStatus _status = ReadingStatus.okunuyor;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedEmoji;
  String? _selectedCategory;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.book != null) {
      final book = widget.book!;
      _titleController.text = book.title;
      _authorController.text = book.author;
      _summaryController.text = book.summary;
      _feelingsController.text = book.feelings;
      _quotesController.text = book.quotes;
      _bookImage = book.imageUrl;
      _status = book.status;
      _startDate = book.startDate;
      _endDate = book.endDate;
    }
  }

  void _selectBook(Book book) {
    setState(() {
      _searchController.clear();
      _titleController.text = book.title;
      _authorController.text = book.author;
      _bookImage = book.imageUrl.isNotEmpty ? book.imageUrl : null;
      _showSuggestions = false;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        _bookImage = image.path;
      });
    }
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => isStart ? _startDate = picked : _endDate = picked);
    }
  }

  void _saveBook() async {
    if (_startDate != null && _endDate != null && _startDate!.isAfter(_endDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Bitiş tarihi başlangıç tarihinden önce olamaz!"), backgroundColor: Colors.red),
      );
      return;
    }

    if (_titleController.text.isEmpty || _authorController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Kitap adı ve yazar boş olamaz!"), backgroundColor: Colors.red),
      );
      return;
    }

    Future<void> _showCompletionDialog() async {
      List<String> emojis = ['😍', '🙂', '😐', '😢', '😡'];

      await AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.topSlide,
        title: 'Kitabı Tamamladın!',
        desc: 'Kitabı nasıl değerlendirirsin?',
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Kitabı nasıl değerlendirirsin?", style: TextStyle(fontSize: 18)),
            SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: emojis.map((emoji) => GestureDetector(
                onTap: () {
                  setState(() => _selectedEmoji = emoji);
                  Navigator.of(context).pop();
                },
                child: Text(emoji, style: TextStyle(fontSize: 30)),
              )).toList(),
            ),
          ],
        ),
        btnCancelOnPress: () => _selectedEmoji = null,
        btnCancelText: "Vazgeç",
        btnCancelColor: AppPallete.gradient2,
        dismissOnTouchOutside: false,
        dialogBackgroundColor: AppPallete.backgroundColor,
        buttonsTextStyle: TextStyle(color: AppPallete.gradient3),
      ).show();
    }

    if (_endDate != null && _selectedEmoji == null) {
      await _showCompletionDialog();
      if (_selectedEmoji == null) return;
    }

    _status = _endDate != null ? ReadingStatus.okundu : ReadingStatus.okunuyor;

    final book = Book(
      id: widget.book?.id ?? Uuid().v4(),
      title: _titleController.text.trim(),
      author: _authorController.text.trim(),
      summary: _summaryController.text.trim(),
      feelings: _feelingsController.text.trim(),
      quotes: _quotesController.text.trim(),
      imageUrl: _bookImage != null && _bookImage!.startsWith('http') ? _bookImage! : '',
      imagePath: _bookImage != null && !_bookImage!.startsWith('http') ? _bookImage! : '',
      description: _selectedEmoji ?? '',
      status: _status,
      startDate: _startDate,
      endDate: _endDate,
      category: _selectedCategory ?? 'Bilinmeyen',
    );

    context.read<BookBloc>().add(ClearSearchResultsEvent());
    widget.book == null
        ? context.read<BookBloc>().add(AddBook(book))
        : context.read<BookBloc>().add(UpdateBook(book));
  }
  
void _showImageSourceDialog() {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text("Fotoğraf Seç"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.camera_alt, color: AppPallete.gradient1),
            title: Text("Fotoğraf Çek"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
          ),
          ListTile(
            leading: Icon(Icons.photo_library, color: AppPallete.gradient1),
            title: Text("Galeriden Seç"),
            onTap: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTextField(TextEditingController controller, String label, {int maxLines = 1}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.01),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: TextStyle(fontSize: screenWidth * 0.04),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(
            vertical: screenHeight * 0.012,
            horizontal: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }



  Widget _buildSearchSuggestions(BookState state) {
    if (state is BookLoading) return Center(child: CircularProgressIndicator());
    if (state is BookLoaded) {
      if (state.filteredBooks.isEmpty) return Text("Sonuç bulunamadı.");
      return SizedBox(
        height: 200,
        child: ListView.builder(
          itemCount: state.filteredBooks.length,
          itemBuilder: (context, index) {
            final book = state.filteredBooks[index];
            return ListTile(
              leading: book.imageUrl.isNotEmpty ? Image.network(book.imageUrl, width: 50, height: 75, fit: BoxFit.cover) : Icon(Icons.book, size: 50),
              title: Text(book.title),
              subtitle: Text(book.author),
              onTap: () => _selectBook(book),
            );
          },
        ),
      );
    }
    if (state is BookError) return Text("Hata: ${state.message}", style: TextStyle(color: Colors.red));
    return SizedBox.shrink();
  }

  final List<String> defaultCategories = [
    'Roman', 'Kişisel Gelişim', 'Psikoloji', 'Tarih', 'Felsefe', 'Bilim', 'Biyografi',
    'Otobiyografi', 'Şiir', 'Fantastik', 'Bilim Kurgu', 'Gerilim / Polisiye', 'Çocuk Kitapları',
    'Gençlik', 'Edebiyat', 'Din / Spiritüel', 'İş Dünyası / Girişimcilik', 'Ekonomi', 'Sağlık',
    'Beslenme / Diyet', 'Gezi / Seyahat', 'Eğitim / Öğretim', 'Kültür / Sanat', 'Aile / Evlilik',
    'Motivasyon', 'Klasikler', 'Manga / Çizgi Roman', 'Kısa Öykü', 'Deneme / Makale', 'Anı / Hatıra',
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: BlocListener<BookBloc, BookState>(
        listener: (context, state) {
          if (state is BookAddedSuccess || state is BookUpdatedSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state is BookAddedSuccess ? "Kitap başarıyla eklendi!" : "Kitap başarıyla güncellendi!")),
            );
            Navigator.pop(context, state is BookUpdatedSuccess ? state.book : true);
          } else if (state is BookError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Hata: ${state.message}"), backgroundColor: Colors.red),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: Text("Kitap Günlüğü")),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                  child: TextFormField(
                    controller: _searchController,
                    onChanged: (value) {
                      context.read<BookBloc>().add(SearchBooksFromGoogle(value));
                      setState(() => _showSuggestions = true);
                    },
                    style: TextStyle(fontSize: screenWidth * 0.035),
                    decoration: InputDecoration(
                      hintText: 'Kitap ara...',
                      prefixIcon: Icon(Icons.search, size: screenWidth * 0.05, color: AppPallete.gradient1),
                      suffixIcon: IconButton(
                        icon: Icon(Icons.clear, size: screenWidth * 0.05, color: AppPallete.gradient1),
                        onPressed: () {
                          _searchController.clear();
                          context.read<BookBloc>().add(ClearSearchResultsEvent());
                          setState(() => _showSuggestions = false);
                        },
                      ),
                      filled: true,
                      isDense: true,
                      fillColor: AppPallete.backgroundColor,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (_showSuggestions) BlocBuilder<BookBloc, BookState>(builder: (_, state) => _buildSearchSuggestions(state)),
                SizedBox(height: screenHeight * 0.02),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
  onTap: _showImageSourceDialog,
  child: Container(
    width: 120,
    height: 180,
    child: buildBookImage(_bookImage != null && _bookImage!.startsWith('http') ? _bookImage : null,
                        _bookImage != null && !_bookImage!.startsWith('http') ? _bookImage : null,),
  ),


                      ),
                  
                    
                    SizedBox(width: screenWidth * 0.04),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text.isNotEmpty ? _titleController.text : "Kitap Adı",
                            style: TextStyle(fontSize: screenWidth * 0.045, fontWeight: FontWeight.bold, color: AppPallete.gradient2),
                          ),
                          SizedBox(height: 5),
                          Text(
                            _authorController.text.isNotEmpty ? _authorController.text : "Yazar",
                            style: TextStyle(fontSize: screenWidth * 0.03, color: AppPallete.gradient2),
                          ),
                          SizedBox(height: screenHeight * 0.01),
                       SizedBox(
  width: screenWidth * 0.4 < 100 ? 100 : screenWidth * 0.6,
  child: CategorySelector(
    existingCategories: defaultCategories,
    onCategorySelected: (category) => setState(() => _selectedCategory = category),
  ),
),

                        Row(
  children: [
    Expanded(
      child: TextButton(
        onPressed: () => _selectDate(true),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        ),
        child: _startDate == null
            ? Row(
                children: [
                  Icon(Icons.calendar_today, color: AppPallete.gradient1, size: screenWidth * 0.04),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      "Başlangıç Tarihi",
                      style: TextStyle(
                        color: AppPallete.gradient1,
                        fontSize: screenWidth * 0.034,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppPallete.gradient1, size: screenWidth * 0.035),
                      SizedBox(width: 4),
                      Text(
                        "Başlangıç",
                        style: TextStyle(
                          color: AppPallete.gradient1,
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${_startDate!.day}.${_startDate!.month}.${_startDate!.year}",
                    style: TextStyle(
                      color: AppPallete.gradient1,
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    ),
    SizedBox(width: 8),
    Expanded(
      child: TextButton(
        onPressed: () => _selectDate(false),
        style: TextButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        ),
        child: _endDate == null
            ? Row(
                children: [
                  Icon(Icons.calendar_today, color: AppPallete.gradient1, size: screenWidth * 0.04),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Bitiş Tarihi",
                      style: TextStyle(
                        color: AppPallete.gradient1,
                        fontSize: screenWidth * 0.034,
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, color: AppPallete.gradient1, size: screenWidth * 0.035),
                      SizedBox(width: 6),
                      Text(
                        "Bitiş",
                        style: TextStyle(
                          color: AppPallete.gradient1,
                          fontSize: screenWidth * 0.028,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    "${_endDate!.day}.${_endDate!.month}.${_endDate!.year}",
                    style: TextStyle(
                      color: AppPallete.gradient1,
                      fontSize: screenWidth * 0.032,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    ),
  ],
),

                   

                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.02),
                _buildTextField(_summaryController, "Kitabın Ana Konusu", maxLines: 3),
                _buildTextField(_feelingsController, "Kitap Sana Ne Hissettirdi?", maxLines: 3),
                _buildTextField(_quotesController, "Favori Alıntıların", maxLines: 3),
                SizedBox(height: screenHeight * 0.02),
                modernSaveButton(widget.book == null ? "Kitap Ekle" : "Kitap Güncelle", _saveBook),
              ],

            ),
          ),
        ),
      ),
    );
  }
}
