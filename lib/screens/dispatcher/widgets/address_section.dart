import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Секция адреса доставки
class AddressSection extends StatelessWidget {
  final TextEditingController addressController;
  final VoidCallback onGeocodeAddress;
  final bool isLoading;

  const AddressSection({
    super.key,
    required this.addressController,
    required this.onGeocodeAddress,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'כתובת משלוח', // Delivery Address
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: addressController,
          decoration: InputDecoration(
            labelText: l10n.address,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.location_on),
              onPressed: isLoading ? null : onGeocodeAddress,
              tooltip: 'מצא כתובת', // Find Address
            ),
          ),
          maxLines: 2,
        ),
      ],
    );
  }
}
