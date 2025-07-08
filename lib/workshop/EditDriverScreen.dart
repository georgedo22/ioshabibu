import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'workshopDashboard.dart';

class EditDriverScreen extends StatefulWidget {
  final Map<String, dynamic> driverData;
  final Function? onDriverUpdated; // إضافة هذا المتغير
  const EditDriverScreen(
      {Key? key, required this.driverData, this.onDriverUpdated})
      : super(key: key);

  @override
  _EditDriverScreenState createState() => _EditDriverScreenState();
}

class _EditDriverScreenState extends State<EditDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleIdController = TextEditingController();

  File? _licenseImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  String? _currentLicenseImageUrl;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    _nameController.text = widget.driverData['driver_name'] ?? '';
    _phoneController.text = widget.driverData['driver_phone'] ?? '';
    _vehicleIdController.text =
        widget.driverData['vehicle_id']?.toString() ?? '';
    _currentLicenseImageUrl = widget.driverData['license_image'];

    print('Driver Data: ${widget.driverData}');
  }

// تحديث دالة اختيار الصورة لتتضمن التحقق

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _licenseImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في اختيار الصورة: $e');
    }
  }

//////
  Future<void> _takePicture() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _licenseImage = File(image.path);
          print("_licenseImage ${_licenseImage}");
        });
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في التقاط الصورة: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Choose image source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a picture'),
                onTap: () {
                  Navigator.pop(context);
                  _takePicture();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Pick from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _updateDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_driver_info.php'),
      );

      // إضافة معرف السائق (مطلوب دائماً)
      request.fields['id'] = widget.driverData['driver_id'].toString();

      // إضافة الحقول المحدثة فقط إذا تم تغييرها
      if (_nameController.text.trim() != widget.driverData['driver_name']) {
        request.fields['name'] = _nameController.text.trim();
      }

      if (_phoneController.text.trim() != widget.driverData['driver_phone']) {
        request.fields['phone'] = _phoneController.text.trim();
      }

      if (_vehicleIdController.text.trim() !=
          widget.driverData['vehicle_id']?.toString()) {
        request.fields['vehicle_id'] = _vehicleIdController.text.trim();
      }

      // إضافة الصورة إذا تم اختيار صورة جديدة
      if (_licenseImage != null) {
        // التحقق من وجود الملف
        if (await File(_licenseImage!.path).exists()) {
          // تحديد نوع الملف بناءً على الامتداد
          String? mimeType = lookupMimeType(_licenseImage!.path);

          // إذا لم يتم تحديد نوع الملف، استخدم نوع افتراضي
          if (mimeType == null) {
            String extension =
                _licenseImage!.path.split('.').last.toLowerCase();
            switch (extension) {
              case 'jpg':
              case 'jpeg':
                mimeType = 'image/jpeg';
                break;
              case 'png':
                mimeType = 'image/png';
                break;
              case 'gif':
                mimeType = 'image/gif';
                break;
              case 'bmp':
                mimeType = 'image/bmp';
                break;
              case 'webp':
                mimeType = 'image/webp';
                break;
              default:
                mimeType = 'image/jpeg'; // افتراضي
            }
          }

          var imageFile = await http.MultipartFile.fromPath(
            'license_image',
            _licenseImage!.path,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(imageFile);

          print('Image added: ${_licenseImage!.path}');
          print('MIME Type: $mimeType');
        } else {
          print('Image file does not exist: ${_licenseImage!.path}');
        }
      }

      // إضافة معلومات تشخيصية
      print('Request fields: ${request.fields}');
      print('Request files: ${request.files.length}');

      var response = await request.send();
      var responseData = await response.stream.bytesToString();

      print('Response Status: ${response.statusCode}');
      print('Response Data: $responseData');

      if (response.statusCode == 200) {
        try {
          var jsonResponse = json.decode(responseData);
          if (jsonResponse['success'] != null) {
            _showSuccessDialog(jsonResponse['success']);
          } else if (jsonResponse['error'] != null) {
            // إذا كان هناك معلومات تشخيصية، اعرضها للمطور
            if (jsonResponse['debug'] != null ||
                jsonResponse['debug_info'] != null) {
              print(
                  'Debug Info: ${jsonResponse['debug'] ?? jsonResponse['debug_info']}');
            }
            _showErrorSnackBar(jsonResponse['error']);
          } else {
            _showErrorSnackBar('خطأ غير متوقع في الاستجابة');
          }
        } catch (e) {
          print('JSON Parse Error: $e');
          print('Raw Response: $responseData');
          _showErrorSnackBar('خطأ في تحليل استجابة الخادم');
        }
      } else {
        try {
          var errorResponse = json.decode(responseData);
          String errorMessage = errorResponse['error'] ?? 'خطأ في الخادم';

          // إضافة معلومات تشخيصية إضافية إذا كانت متوفرة
          if (errorResponse['debug_info'] != null) {
            print('Server Debug Info: ${errorResponse['debug_info']}');
          }

          _showErrorSnackBar(errorMessage);
        } catch (e) {
          print('Error parsing error response: $e');
          print('Raw Error Response: $responseData');
          _showErrorSnackBar('خطأ في الخادم (${response.statusCode})');
        }
      }
    } on SocketException {
      _showErrorSnackBar('خطأ في الاتصال بالإنترنت');
    } on FormatException {
      _showErrorSnackBar('خطأ في تنسيق البيانات');
    } catch (e) {
      print('Unexpected error: $e');
      _showErrorSnackBar('خطأ غير متوقع: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// دالة مساعدة للتحقق من صحة الصورة قبل الرفع (اختيارية)
/*Future<bool> _isValidImage(String imagePath) async {
  try {
    File imageFile = File(imagePath);
    if (!await imageFile.exists()) {
      return false;
    }
    
    // التحقق من حجم الملف (أقل من 10 ميجابايت)
    int fileSize = await imageFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      _showErrorSnackBar('حجم الصورة كبير جداً (أكثر من 10 ميجابايت)');
      return false;
    }
    // التحقق من امتداد الملف
    String extension = imagePath.split('.').last.toLowerCase();
    List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    
    if (!allowedExtensions.contains(extension)) {
      _showErrorSnackBar('نوع الصورة غير مدعوم');
      return false;
    }
    
    return true;
  } catch (e) {
    print('Error validating image: $e');
    return false;
  }
}*/
// تحسين دالة التحقق من صحة الصورة
  Future<bool> _isValidImage(String imagePath) async {
    try {
      // طباعة مسار الصورة للتشخيص
      print('Validating image path: $imagePath');

      // التحقق من وجود الملف
      File imageFile = File(imagePath);
      bool exists = await imageFile.exists();
      if (!exists) {
        print('File does not exist: $imagePath');
        _showErrorSnackBar('الملف غير موجود');
        return false;
      }

      // التحقق من حجم الملف (أقل من 5 ميجابايت للأداء الأفضل)
      try {
        int fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          _showErrorSnackBar('حجم الصورة كبير جداً (أكثر من 5 ميجابايت)');
          return false;
        }
      } catch (e) {
        print('Error checking file size: $e');
        // استمر في التنفيذ حتى لو فشل التحقق من الحجم
      }

      // التحقق من امتداد الملف بطريقة آمنة
      try {
        String extension = '';
        if (imagePath.contains('.')) {
          extension = imagePath.split('.').last.toLowerCase();
        }

        List<String> allowedExtensions = [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'bmp',
          'webp',
          'heic',
          'heif'
        ];

        if (extension.isEmpty || !allowedExtensions.contains(extension)) {
          _showErrorSnackBar(
              'نوع الصورة غير مدعوم. الأنواع المدعومة: ${allowedExtensions.join(', ')}');
          return false;
        }
      } catch (e) {
        print('Error checking file extension: $e');
        // استمر في التنفيذ حتى لو فشل التحقق من الامتداد
      }

      return true;
    } catch (e) {
      print('Error in _isValidImage: $e');
      return false; // لا تظهر رسالة خطأ هنا لتجنب تكرار الرسائل
    }
  }

  /*Future<void> _updateDriver() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://antiquewhite-cobra-422929.hostingersite.com/georgecode/update_driver_info.php'), // غير الرابط حسب الحاجة
      );

      // إضافة معرف السائق (مطلوب)
      request.fields['id'] = widget.driverData['driver_id'].toString();

      // إضافة الحقول المحدثة فقط إذا تم تغييرها
      if (_nameController.text.trim() != widget.driverData['driver_name']) {
        request.fields['name'] = _nameController.text.trim();
      }

      if (_phoneController.text.trim() != widget.driverData['driver_phone']) {
        request.fields['phone'] = _phoneController.text.trim();
      }

      if (_vehicleIdController.text.trim() != widget.driverData['vehicle_id']?.toString()) {
        request.fields['vehicle_id'] =_vehicleIdController.text.trim();
      }

      // إضافة الصورة إذا تم اختيار صورة جديدة
      if (_licenseImage != null) {
        var imageFile = await http.MultipartFile.fromPath(
          'license_image',
          _licenseImage!.path,
        );
        request.files.add(imageFile);
      }

      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var jsonResponse = json.decode(responseData);
        if (jsonResponse['success'] != null) {
          _showSuccessDialog(jsonResponse['success']);
        } else {
          _showErrorSnackBar('خطأ غير متوقع في الاستجابة');
        }
      } else {
        var errorResponse = json.decode(responseData);
        _showErrorSnackBar(errorResponse['error'] ?? 'خطأ في الخادم');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ في الاتصال: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }*/

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 48,
          ),
          content: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (widget.onDriverUpdated != null) {
                  widget.onDriverUpdated!();
                }
                Navigator.pop(context);
                Navigator.pop(context, true);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Driver license image',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            if (_licenseImage != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    _licenseImage!,
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else if (_currentLicenseImageUrl != null &&
                _currentLicenseImageUrl!.isNotEmpty)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://antiquewhite-cobra-422929.hostingersite.com/georgecode/image_proxy.php?url=https://antiquewhite-cobra-422929.hostingersite.com/georgecode/${_currentLicenseImageUrl}',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.broken_image,
                            size: 64, color: Colors.grey),
                      );
                    },
                  ),
                ),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border:
                      Border.all(color: Colors.grey, style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    'No image selected',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Change image'),
                  ),
                ),
                if (_licenseImage != null) ...[
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _licenseImage = null;
                      });
                    },
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit driver information'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Driver name',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Driver name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Driver name must be more than one character';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone number',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          if (value.trim().length < 10) {
                            return 'Invalid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _vehicleIdController,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle ID (optional)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.directions_car),
                          helperText:
                              'Leave empty if you do not want to change the vehicle',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final vehicleId = int.tryParse(value.trim());
                            if (vehicleId == null || vehicleId <= 0) {
                              return 'Vehicle ID must be a valid number';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildImageSection(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateDriver,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 10),
                            Text('Updating...'),
                          ],
                        )
                      : const Text(
                          'Update information',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleIdController.dispose();
    super.dispose();
  }
}
