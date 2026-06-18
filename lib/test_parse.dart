import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseKey = dotenv.env['SUPABASE_ANON_KEY']!;
  
  final client = SupabaseClient(supabaseUrl, supabaseKey);
  
  try {
    final response = await client.from('businesses').select('*, categories(name)');
    for (var biz in response) {
      try {
        // Test parsing each business
        final name = biz['name'];
        
        // 1. Check categories
        if (biz['categories'] != null) {
          final cat = biz['categories'];
          if (cat is Map) {
            final catName = cat['name'] as String;
          } else if (cat is List) {
            print('Categories is a List! $cat');
          }
        }
        
        // 2. Check services
        if (biz['services'] is List) {
           (biz['services'] as List).map((e) => Map<String, String>.from(e as Map)).toList();
        }

        // 3. Check galleryUrls
        if (biz['gallery_urls'] != null) {
          List<String>.from(biz['gallery_urls'] as List? ?? []);
        }

      } catch (e, stack) {
        print('Error parsing business ${biz['name']}: $e');
        print('Business data: $biz');
      }
    }
    print('Done checking businesses.');
  } catch (e) {
    print('Failed to fetch businesses: $e');
  }
}
