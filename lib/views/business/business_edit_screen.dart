import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/category_model.dart';
import '../../services/mock_data_service.dart';

class BusinessEditScreen extends StatefulWidget {
  const BusinessEditScreen({super.key});

  static const routeName = '/business/edit';

  @override
  State<BusinessEditScreen> createState() => _BusinessEditScreenState();
}

class _BusinessEditScreenState extends State<BusinessEditScreen> {
  final _formKeys = [
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
    GlobalKey<FormState>(),
  ];

  late Future<List<CategoryModel>> _categoriesFuture;
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: General info (pre-filled mock data)
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  CategoryModel? _selectedCategory;

  // Step 2: Contact info
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  final double _latitude = -18.8792;
  final double _longitude = 47.5079;

  // Step 3: Media
  String? _logoUrl;
  List<String> _galleryUrls = [];

  // Step 4: Opening hours
  final Map<String, Map<String, dynamic>> _openingHours = {
    'Lundi': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'Mardi': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'Mercredi': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'Jeudi': {'isOpen': true, 'open': '09:00', 'close': '22:00'},
    'Vendredi': {'isOpen': true, 'open': '09:00', 'close': '23:00'},
    'Samedi': {'isOpen': true, 'open': '10:00', 'close': '23:00'},
    'Dimanche': {'isOpen': true, 'open': '10:00', 'close': '22:00'},
  };

  // Step 5: Services
  final List<Map<String, String>> _services = [
    {'name': 'Terrasse', 'price': '0'},
    {'name': 'Climatisation', 'price': '0'},
    {'name': 'Parking', 'price': '5000'},
  ];

  @override
  void initState() {
    super.initState();
    _initializeWithMockData();
    _categoriesFuture = MockDataService().getCategories();
  }

  void _initializeWithMockData() {
    // Pre-fill with mock data from "La Varangue" business
    _nameController = TextEditingController(text: 'La Varangue');
    _descriptionController = TextEditingController(
      text:
          'Une adresse locale apprécié pour son accueil, la qualité du service et son ambiance soignée. Réservation facile, accueil chaleureux et excellente recommandation de menu.',
    );
    _addressController = TextEditingController(
      text: 'Analakely, 101 Antananarivo, Madagascar',
    );
    _phoneController = TextEditingController(text: '+261 34 00 000 00');
    _emailController = TextEditingController(text: 'contact@lavarangue.mg');
    _logoUrl = 'https://picsum.photos/seed/reviewapp-restaurant/600/420';
    _galleryUrls = [
      'https://picsum.photos/seed/gallery-restaurant-1/400/300',
      'https://picsum.photos/seed/gallery-restaurant-2/400/300',
    ];
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
    if (_currentStep < 4) {
      if (_currentStep == 0 && !_formKeys[0].currentState!.validate()) {
        return;
      }
      if (_currentStep == 1 && !_formKeys[1].currentState!.validate()) {
        return;
      }
      setState(() => _currentStep += 1);
    } else {
      _saveChanges();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSubmitting = true);

    try {
      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Modifications enregistrées avec succès !'),
          duration: Duration(seconds: 2),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        context.go('/business/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _confirmDeleteBusiness() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: const Icon(Icons.delete_outline_rounded),
          title: const Text('Supprimer cette entreprise ?'),
          content: const Text(
            'Cette action supprimera votre entreprise et tous les avis associés. Cette opération est irréversible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (shouldDelete == true) {
      setState(() => _isSubmitting = true);

      try {
        await Future<void>.delayed(const Duration(milliseconds: 800));

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Entreprise supprimée avec succès.'),
            duration: Duration(seconds: 2),
          ),
        );

        await Future<void>.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          context.go('/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erreur: $e')));
          setState(() => _isSubmitting = false);
        }
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

  Future<void> _pickLogo() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Choisir une image'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                setState(
                  () => _logoUrl =
                      'https://picsum.photos/seed/logo-${DateTime.now().millisecond}/300/300',
                );
              },
              child: const Text('Depuis la galerie'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _logoUrl = 'https://i.pravatar.cc/300');
              },
              child: const Text('Prendre une photo'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickGalleryPhotos() async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return SimpleDialog(
          title: const Text('Ajouter une photo'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                if (_galleryUrls.length < 6) {
                  setState(
                    () => _galleryUrls.add(
                      'https://picsum.photos/seed/gallery-${DateTime.now().millisecond}/400/300',
                    ),
                  );
                }
              },
              child: const Text('Depuis la galerie'),
            ),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                if (_galleryUrls.length < 6) {
                  setState(
                    () => _galleryUrls.add(
                      'https://picsum.photos/seed/camera-${DateTime.now().millisecond}/400/300',
                    ),
                  );
                }
              },
              child: const Text('Prendre une photo'),
            ),
          ],
        );
      },
    );
  }

  void _addService() {
    showDialog<void>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController();
        final priceController = TextEditingController();

        return AlertDialog(
          title: const Text('Ajouter un service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du service',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix (Ar)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _services.add({
                      'name': nameController.text,
                      'price': priceController.text,
                    });
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }

  void _editService(int index) {
    showDialog<void>(
      context: context,
      builder: (context) {
        final nameController = TextEditingController(
          text: _services[index]['name'],
        );
        final priceController = TextEditingController(
          text: _services[index]['price'],
        );

        return AlertDialog(
          title: const Text('Modifier le service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du service',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Prix (Ar)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _services[index] = {
                      'name': nameController.text,
                      'price': priceController.text,
                    };
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'entreprise'),
        centerTitle: false,
      ),
      body: Theme(
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
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
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
                          initialValue: _selectedCategory ?? categories.first,
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
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
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
                        labelText: 'Email',
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
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              title: const Text('Médias'),
              content: Form(
                key: _formKeys[2],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'Logo',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: _pickLogo,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outlineVariant,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _logoUrl == null
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
                                child: Image.network(
                                  _logoUrl!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Galerie (maximum 6 photos)',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_galleryUrls.isNotEmpty)
                      GridView.count(
                        crossAxisCount: 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        children: [
                          ..._galleryUrls.map(
                            (url) => Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(url, fit: BoxFit.cover),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() => _galleryUrls.remove(url));
                                    },
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: colorScheme.error,
                                        borderRadius: BorderRadius.circular(20),
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
                          if (_galleryUrls.length < 6)
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
                    if (_galleryUrls.isEmpty)
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
              state: _currentStep > 3 ? StepState.complete : StepState.indexed,
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
                            side: BorderSide(color: colorScheme.outlineVariant),
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
                                        setState(() => hours['isOpen'] = value);
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
                                          onTap: () => _selectTime(day, 'open'),
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color:
                                                    colorScheme.outlineVariant,
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
                                                color:
                                                    colorScheme.outlineVariant,
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
                                            color: colorScheme.onSurfaceVariant,
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

            // Step 5: Services
            Step(
              isActive: _currentStep >= 4,
              state: _currentStep > 4 ? StepState.complete : StepState.indexed,
              title: const Text('Services'),
              content: Form(
                key: _formKeys[4],
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Services et tarifs',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        FilledButton.icon(
                          onPressed: _addService,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ajouter'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_services.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'Aucun service ajouté',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _services.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final service = _services[index];
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.outlineVariant,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service['name']!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          service['price']!.isEmpty
                                              ? 'Gratuit'
                                              : '${service['price']} Ar',
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded),
                                    onPressed: () => _editService(index),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                    onPressed: () {
                                      setState(() => _services.removeAt(index));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
          onStepTapped: (step) {
            if (step < _currentStep) {
              setState(() => _currentStep = step);
            }
          },
        ),
      ),
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
                Text('Traitement en cours...'),
              ],
            ),
          )
        else
          Expanded(
            child: Row(
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
                    _currentStep == 4
                        ? Icons.check_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(_currentStep == 4 ? 'Enregistrer' : 'Suivant'),
                ),
              ],
            ),
          ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSubmitting ? null : _confirmDeleteBusiness,
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Theme.of(context).colorScheme.onError,
        icon: const Icon(Icons.delete_outline_rounded),
        label: const Text('Supprimer'),
      ),
    );
  }
}
