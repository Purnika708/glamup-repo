import 'package:flutter/material.dart';
import 'package:glamup/models/category.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final bool isSelected;
  final Function()? onTap;

  const CategoryCard({
    Key? key,
    required this.category,
    this.isSelected = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected 
                ? Theme.of(context).primaryColor.withOpacity(0.2) 
                : Colors.grey.withOpacity(0.1),
              blurRadius: isSelected ? 8 : 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor.withOpacity(0.2) : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  _getCategoryIcon(category.name),
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade700,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                category.name,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Theme.of(context).primaryColor : Colors.black87,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            // Small description indicator
            if (category.description.isNotEmpty)
              Container(
                width: isSelected ? 40 : 30,
                height: 3,
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).primaryColor : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    
    if (name.contains('skin')) {
      return Icons.spa;
    } else if (name.contains('hair')) {
      return Icons.face_retouching_natural;
    } else if (name.contains('frag') || name.contains('perfume')) {
      return Icons.air;
    } else if (name.contains('access') || name.contains('tool')) {
      return Icons.shopping_bag;
    } else if (name.contains('eye')) {
      return Icons.remove_red_eye;
    } else if (name.contains('face')) {
      return Icons.tag_faces;
    } else if (name.contains('nail')) {
      return Icons.clean_hands;
    } 
    else if (name.contains('men')){
      return Icons.face_5_rounded;
    }
    else {
      return Icons.category;
    }
  }
}