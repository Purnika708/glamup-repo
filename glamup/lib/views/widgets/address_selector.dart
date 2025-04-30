import 'package:flutter/material.dart';
import 'package:glamup/models/address.dart';

class AddressSelector extends StatelessWidget {
  final List<Address> addresses;
  final Address? selectedAddress;
  final bool isLoadingAddresses;
  final VoidCallback onTap;

  const AddressSelector({
    Key? key,
    required this.addresses,
    required this.selectedAddress,
    required this.isLoadingAddresses,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.pink.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on,
                color: Colors.pink.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Deliver to:',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      if (addresses.isEmpty && !isLoadingAddresses)
                        Text(
                          ' (Add address)',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.pink.shade400,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  isLoadingAddresses
                      ? const SizedBox(
                          height: 20,
                          child: Center(
                            child: LinearProgressIndicator(
                              minHeight: 2,
                            ),
                          ),
                        )
                      : selectedAddress == null
                          ? const Text(
                              'Select delivery address',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedAddress!.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _formatAddressLine(selectedAddress!),
                                  style: const TextStyle(fontSize: 12),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  String _formatAddressLine(Address address) {
    return '${address.addressLine}, ${address.city}, ${address.state} ${address.zipCode}';
  }
}