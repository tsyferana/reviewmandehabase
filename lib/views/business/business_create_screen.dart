import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../models/category_model.dart';
import '../../services/supabase_data_service.dart';

class BusinessCreateScreen extends StatefulWidget {
  const BusinessCreateScreen({super.key});

  static const routeName = '/business/create';

  @override
  State<BusinessCreateScreen> createState() => _BusinessCreateScreenState();
}

class _BusinessCreateScreenState extends State<BusinessCreateScreen> {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  late Future<List<CategoryModel>> _categoriesFuture;
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: General info
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  CategoryModel? _selectedCategory;

  // Step 2: Contact info
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  double _latitude = -18.8792;
  double _longitude = 47.5079;

  // Step 3: Media
  File? _logoFile;
  final List<File> _galleryFiles = [];

  // Step 4: Opening hours
  final Map<String, Map<String, dynamic>> _openingHours = {
    'Lundi': {'isOpen': true, 'open': '08:00', 'close': '18:00'},
    'Mardi': {'isOpen': true, 'open': '08:00', 'close': '18:00'},
    'Mercredi': {'isOpen': true, 'open': '08:00', 'close': '18:00'},
    'Jeudi': {'isOpen': true, 'open': '08:00', 'close': '18:00'},
    'Vendredi': {'isOpen': true, 'open': '08:00', 'close': '18:00'},
    'Samedi': {'isOpen': true, 'open': '09:00', 'close': '17:00'},
    'Dimanche': {'isOpen': false, 'open': '00:00', 'close': '00:00'},
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _addressController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _categoriesFuture = SupabaseDataService().getCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_formKeys[0].currentState!.validate()) {
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 1) {
      if (_formKeys[1].currentState!.validate()) {
        setState(() => _currentStep += 1);
      }
    } else if (_currentStep == 2) {
      setState(() => _currentStep += 1);
    } else if (_currentStep == 3) {
      _submitForm();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _submitForm() async {
    setState(() => _isSubmitting = true);

    try {
      if (_selectedCategory == null) throw 'Veuillez sélectionner une catégorie.';
      
      await SupabaseDataService().createBusiness(
        name: _nameController.text.trim(),
        categoryId: _selectedCategory!.id,
        description: _descriptionController.text.trim(),
        address: _addressController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        openingHours: _openingHours,
        logoFile: _logoFile,
        galleryFiles: _galleryFiles,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entreprise créée avec succès ! En attente d\'approbation.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      context.go('/home');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _selectTime(String day, String period) async {
    final hours = _openingHours[day];
    if (hours == null) return;

    final initialTime = period == 'open'
        ? TimeOfDay.fromDateTime(DateFormat.Hm().parse(hours['open'] as String))
        : TimeOfDay.fromDateTime(
            DateFormat.Hm().parse(hours['close'] as String),
          );

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (pickedTime != null) {
      final formattedTime =
          '${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (period == 'open') {
          hours['open'] = formattedTime;
        } else {
          hours['close'] = formattedTime;
        }
      });
    }
  }

  Future<void> _pickLocationOnMap() async {
    LatLng selectedPos = LatLng(_latitude, _longitude);
    final result = await showDialog<LatLng>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sélectionner la position'),
              content: SizedBox(
                width: double.maxFinite,
                height: 400,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 48, color: Colors.grey.shade600),
                        const SizedBox(height: 8),
                        Text(
                          'Google Maps désactivé\n(Clé API manquante)',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, selectedPos),
                  child: const Text('Valider'),
                ),
              ],
            );
          }
        );
      }
    );

    if (result != null) {
      setState(() {
        _latitude = result.latitude;
        _longitude = result.longitude;
      });
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _logoFile = File(pickedFile.path));
    }
  }

  Future<void> _pickGalleryPhotos() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        for (var file in pickedFiles) {
          if (_galleryFiles.length < 6) {
            _galleryFiles.add(File(file.path));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une entreprise'),
        centerTitle: false,
      ),
      body: PopScope(
        canPop: _currentStep == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        child: Theme(
          data: Theme.of(context).copyWith(),
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _isSubmitting ? null : _onStepContinue,
            onStepCancel: _isSubmitting ? null : _onStepCancel,
            physics: const ScrollPhysics(),
            steps: [
              // Step 1: General Info
              Step(
                isActive: _currentStep >= 0,
                state: _currentStep > 0
                    ? StepState.complete
                    : StepState.indexed,
                title: const Text('Informations générales'),
                content: Form(
                  key: _formKeys[0],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nom de l\'entreprise',
                          prefixIcon: Icon(Icons.business_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Veuillez saisir le nom de votre entreprise.';
                          }
                          if (value!.trim().length < 3) {
                            return 'Le nom doit contenir au moins 3 caractères.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      FutureBuilder<List<CategoryModel>>(
                        future: _categoriesFuture,
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final categories = snapshot.data!;
                          return DropdownButtonFormField<CategoryModel>(
                            initialValue: _selectedCategory,
                            decoration: const InputDecoration(
                              labelText: 'Catégorie',
                              prefixIcon: Icon(Icons.category_rounded),
                              border: OutlineInputBorder(),
                            ),
                            items: categories.map((category) {
                              return DropdownMenuItem(
                                value: category,
                                child: Row(
                                  children: [
                                    Icon(category.icon, size: 20),
                                    const SizedBox(width: 8),
                                    Text(category.name),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) =>
                                setState(() => _selectedCategory = value),
                            validator: (value) {
                              if (value == null) {
                                return 'Veuillez sélectionner une catégorie.';
                              }
                              return null;
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Décrivez votre entreprise...',
                          prefixIcon: Icon(Icons.description_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Veuillez saisir une description.';
                          }
                          if (value!.trim().length < 10) {
                            return 'La description doit contenir au moins 10 caractères.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Step 2: Contact Info
              Step(
                isActive: _currentStep >= 1,
                state: _currentStep > 1
                    ? StepState.complete
                    : StepState.indexed,
                title: const Text('Coordonnées'),
                content: Form(
                  key: _formKeys[1],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Adresse complète',
                          prefixIcon: Icon(Icons.location_on_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Veuillez saisir une adresse.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Position: ${_latitude.toStringAsFixed(4)}, ${_longitude.toStringAsFixed(4)}',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickLocationOnMap,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.map_rounded, size: 32, color: Colors.grey.shade600),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Google Maps désactivé',
                                        style: TextStyle(color: Colors.grey.shade700),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Text(
                                    'Appuyer pour simuler une position',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Téléphone',
                          prefixIcon: Icon(Icons.phone_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.trim().isEmpty ?? true) {
                            return 'Veuillez saisir un numéro de téléphone.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email (optionnel)',
                          prefixIcon: Icon(Icons.email_rounded),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value?.isNotEmpty ?? false) {
                            final isEmailValid = RegExp(
                              r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                            ).hasMatch(value!);
                            if (!isEmailValid) {
                              return 'Veuillez saisir un email valide.';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),

              // Step 3: Media
              Step(
                isActive: _currentStep >= 2,
                state: _currentStep > 2
                    ? StepState.complete
                    : StepState.indexed,
                title: const Text('Médias'),
                content: Form(
                  key: _formKeys[2],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      Text(
                        'Logo',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: _pickLogo,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outlineVariant,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: _logoFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate_rounded,
                                      size: 40,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ajouter un logo',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.file(
                                    _logoFile!,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Galerie (maximum 6 photos)',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      if (_galleryFiles.isNotEmpty)
                        GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            ..._galleryFiles.map(
                              (file) => Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      file,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(
                                          () => _galleryFiles.remove(file),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.error,
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.close_rounded,
                                          color: colorScheme.onError,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_galleryFiles.length < 6)
                              InkWell(
                                onTap: _pickGalleryPhotos,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest
                                        .withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: colorScheme.outlineVariant,
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.add_rounded,
                                    color: colorScheme.primary,
                                    size: 28,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      if (_galleryFiles.isEmpty)
                        InkWell(
                          onTap: _pickGalleryPhotos,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: double.infinity,
                            height: 120,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorScheme.outlineVariant,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_rounded,
                                  size: 40,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Ajouter des photos',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Step 4: Opening Hours
              Step(
                isActive: _currentStep >= 3,
                state: _currentStep > 3
                    ? StepState.complete
                    : StepState.indexed,
                title: const Text('Horaires'),
                content: Form(
                  key: _formKeys[3],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),
                      ..._openingHours.entries.map((entry) {
                        final day = entry.key;
                        final hours = entry.value;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          day,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                      ),
                                      Switch(
                                        value: hours['isOpen'] as bool,
                                        onChanged: (value) {
                                          setState(
                                            () => hours['isOpen'] = value,
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                  if (hours['isOpen'] as bool) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: InkWell(
                                            onTap: () =>
                                                _selectTime(day, 'open'),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: colorScheme
                                                      .outlineVariant,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Ouverture',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.labelSmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    hours['open'] as String,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: InkWell(
                                            onTap: () =>
                                                _selectTime(day, 'close'),
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: colorScheme
                                                      .outlineVariant,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'Fermeture',
                                                    style: Theme.of(
                                                      context,
                                                    ).textTheme.labelSmall,
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    hours['close'] as String,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w800,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ] else
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        'Fermé ce jour',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
            onStepTapped: (step) {
              // Allow going back to previous steps
              if (step < _currentStep) {
                setState(() => _currentStep = step);
              }
            },
          ), // End Stepper
        ), // End Theme
      ), // End PopScope
      persistentFooterButtons: [
        if (_isSubmitting)
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                SizedBox(width: 12),
                Text('Création en cours...'),
              ],
            ),
          )
        else
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              if (_currentStep > 0)
                OutlinedButton.icon(
                  onPressed: _onStepCancel,
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Précédent'),
                ),
              FilledButton.icon(
                onPressed: _onStepContinue,
                icon: Icon(
                  _currentStep == 3
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(_currentStep == 3 ? 'Soumettre' : 'Suivant'),
              ),
            ],
          ),
      ],
    );
  }
}
